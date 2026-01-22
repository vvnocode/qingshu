#!/bin/bash
# Incus 统一管理脚本（支持 LXC 容器 + KVM 虚拟机）
# 用法: ./incus_manage.sh create <名称> <SSH端口>   # 交互式创建
#       ./incus_manage.sh delete <名称>             # 删除实例
#       ./incus_manage.sh status                    # 查看存储状态

set -e

# ================= LXC 默认配置 =================
LXC_CPU=1
LXC_CPU_ALLOWANCE="40ms/100ms"
LXC_MEM="400MiB"
LXC_DISK="5GB"
LXC_PORT_COUNT=9999
LXC_BANDWIDTH=""
LXC_IMAGE="images:debian/13"
LXC_BLOCK_CN="false"


# ================= KVM 默认配置 =================
KVM_CPU=1
KVM_MEM="460MiB"
KVM_DISK="5GB"
KVM_PORT_COUNT=9999
KVM_BANDWIDTH=""
KVM_IMAGE="images:debian/13"
KVM_SECUREBOOT="false"
KVM_BLOCK_CN="false"


# ================= 扩展功能配置 =================
CN_IP_SET_URL="https://raw.githubusercontent.com/herrbischoff/country-ip-blocks/master/ipv4/cn.cidr"


# ============================================================

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "Error: 必须使用 root 权限运行"
        exit 1
    fi
}

# 检查并配置 ipset
check_ipset() {
    if ! command -v ipset >/dev/null 2>&1; then
        echo ">> 安装 ipset..."
        apt-get update -y >/dev/null 2>&1
        apt-get install -y ipset >/dev/null 2>&1
    fi

    # 检查 cn_ip 集合是否存在
    if ! ipset list cn_ip >/dev/null 2>&1; then
        echo ">> 创建 China IP 集合 (cn_ip)..."
        ipset create cn_ip hash:net
        echo ">> 下载并导入 CN IP 到 ipset..."
        # 临时文件
        local tmp_file="/tmp/cn_ip.cidr"
        if curl -sL "$CN_IP_SET_URL" -o "$tmp_file"; then
            echo "   正在导入规则 (可能需要几秒钟)..."
            # 批量导入以提高速度
            sed 's/^/add cn_ip /' "$tmp_file" | ipset restore -!
            rm -f "$tmp_file"
            echo "   ✅ CN IP 集合创建完成"
        else
            echo "   ❌ 下载 CN IP 列表失败，跳过屏蔽功能"
            return 1
        fi
    fi
    return 0
}

# 屏蔽 CN IP 访问特定端口
block_cn_ports() {
    local ssh_port="$1"
    local port_start="$2"
    local port_end="$3"

    # 检查 ipset 是否可用
    if ! ipset list cn_ip >/dev/null 2>&1; then
        echo "⚠️  cn_ip 集合不存在，跳过屏蔽"
        return
    fi
    
    echo ">> 配置防火墙规则 (禁止中国大陆 IP 访问)..."
    
    # 使用 raw 表 PREROUTING 链，在 NAT 和路由决策之前拦截
    # 这样既能拦截 LXC (INPUT)，也能拦截 KVM NAT (FORWARD)
    # SSH 端口
    iptables -t raw -I PREROUTING -p tcp --dport "$ssh_port" -m set --match-set cn_ip src -j DROP
    
    # 端口范围 (TCP + UDP)
    # 端口范围 (TCP + UDP)
    iptables -t raw -I PREROUTING -p tcp --dport "${port_start}:${port_end}" -m set --match-set cn_ip src -j DROP
    iptables -t raw -I PREROUTING -p udp --dport "${port_start}:${port_end}" -m set --match-set cn_ip src -j DROP
    
    echo "   ✅ 已添加防火墙规则 (SSH: $ssh_port, Ports: $port_start-$port_end)"
    echo "   ⚠️  注意: 规则仅当前生效，重启宿主机后需要重新添加 (除非安装 iptables-persistent)"
}

# 解除屏蔽
unblock_cn_ports() {
    local ssh_port="$1"
    local port_start="$2"
    local port_end="$3"
    
    echo ">> 移除防火墙屏蔽规则..."
    
    # 尝试删除规则，即使不存在也不报错
    # 尝试删除规则，即使不存在也不报错
    # 先清理 INPUT (旧版本兼容)
    iptables -D INPUT -p tcp --dport "$ssh_port" -m set --match-set cn_ip src -j DROP 2>/dev/null || true
    iptables -D INPUT -p tcp --dport "${port_start}:${port_end}" -m set --match-set cn_ip src -j DROP 2>/dev/null || true
    iptables -D INPUT -p udp --dport "${port_start}:${port_end}" -m set --match-set cn_ip src -j DROP 2>/dev/null || true

    # 清理 raw PREROUTING
    iptables -t raw -D PREROUTING -p tcp --dport "$ssh_port" -m set --match-set cn_ip src -j DROP 2>/dev/null || true
    iptables -t raw -D PREROUTING -p tcp --dport "${port_start}:${port_end}" -m set --match-set cn_ip src -j DROP 2>/dev/null || true
    iptables -t raw -D PREROUTING -p udp --dport "${port_start}:${port_end}" -m set --match-set cn_ip src -j DROP 2>/dev/null || true
    
    echo "   ✅ 已移除相关防火墙规则"
}

# 检查并修复系统临时端口范围
check_ephemeral_ports() {
    local port_range
    port_range=$(cat /proc/sys/net/ipv4/ip_local_port_range 2>/dev/null)
    local low_port high_port
    read low_port high_port <<< "$port_range"
    
    # 如果系统临时端口范围和 Incus 推荐端口范围（20000+）重叠，提示修复
    if [ "$high_port" -gt 19999 ] 2>/dev/null; then
        echo ""
        echo "⚠️  检测到系统临时端口范围: $low_port-$high_port"
        echo "   这可能与 Incus 端口映射冲突"
        echo ""
        read -rp "是否自动修改为 10000-19999 以避免冲突？[Y/n] " fix_ports
        if [ "$fix_ports" != "n" ] && [ "$fix_ports" != "N" ]; then
            echo "10000 19999" > /proc/sys/net/ipv4/ip_local_port_range
            # 永久生效
            if ! grep -q "net.ipv4.ip_local_port_range" /etc/sysctl.conf 2>/dev/null; then
                echo "net.ipv4.ip_local_port_range = 10000 19999" >> /etc/sysctl.conf
            else
                sed -i 's/net.ipv4.ip_local_port_range.*/net.ipv4.ip_local_port_range = 10000 19999/' /etc/sysctl.conf
            fi
            echo "   ✅ 已修改系统临时端口范围为 10000-19999"
            echo "   ℹ️  Incus 可用端口范围: 20000-65535"
        else
            echo "   ⚠️  未修改，创建实例时可能遇到端口冲突"
            echo "   ℹ️  建议手动执行: echo '10000 19999' > /proc/sys/net/ipv4/ip_local_port_range"
        fi
        echo ""
    fi
}

# 检查端口是否被占用
check_ports() {
    local ssh_port="$1"
    local port_count="$2"
    local port_start=$((ssh_port + 1))
    local port_end=$((ssh_port + port_count))
    local occupied_ports=""
    
    echo ">> 检查端口可用性..."
    
    # 检查 SSH 端口（系统监听）
    if ss -tlnH 2>/dev/null | grep -qE ":${ssh_port}[[:space:]]"; then
        occupied_ports="$ssh_port"
    fi
    
    # 检查 SSH 端口（Incus 其他实例占用）
    if [ -z "$occupied_ports" ]; then
        for inst in $(incus list -c n --format csv 2>/dev/null); do
            if incus config device show "$inst" 2>/dev/null | grep -qE "listen.*:${ssh_port}$"; then
                occupied_ports="$ssh_port (被实例 $inst 占用)"
                break
            fi
        done
    fi
    
    # 抽样检查端口范围（检查首、中、尾各50个端口）
    local sample_ports=""
    for p in $(seq $port_start $((port_start + 49)) 2>/dev/null); do
        sample_ports="$sample_ports $p"
    done
    local mid=$((port_start + port_count / 2))
    for p in $(seq $mid $((mid + 49)) 2>/dev/null); do
        sample_ports="$sample_ports $p"
    done
    for p in $(seq $((port_end - 49)) $port_end 2>/dev/null); do
        sample_ports="$sample_ports $p"
    done
    
    for port in $sample_ports; do
        if ss -tlnH 2>/dev/null | grep -qE ":${port}[[:space:]]"; then
            if [ -z "$occupied_ports" ]; then
                occupied_ports="$port"
            else
                occupied_ports="$occupied_ports, $port"
            fi
            # 只报告前5个冲突端口
            local cnt
            cnt=$(echo "$occupied_ports" | tr ',' '\n' | wc -l)
            if [ "$cnt" -ge 5 ]; then
                occupied_ports="$occupied_ports ..."
                break
            fi
        fi
    done
    
    if [ -n "$occupied_ports" ]; then
        echo ""
        echo "⚠️  以下端口已被占用: $occupied_ports"
        echo "   请使用其他 SSH 端口重新创建"
        return 1
    fi
    
    echo "   ✅ 端口 ${ssh_port} 和 ${port_start}-${port_end} 可用"
    return 0
}

# 显示存储状态
do_status() {
    echo "==================== Incus 存储状态 ===================="
    
    # 系统磁盘
    echo ""
    echo "系统磁盘:"
    df -h / | tail -1 | awk '{print "  总量: "$2" / 已用: "$3" / 可用: "$4" ("$5" 使用率)"}'
    
    # 存储池
    echo ""
    echo "存储池:"
    incus storage list -f csv 2>/dev/null | while IFS=',' read -r name driver desc state; do
        info=$(incus storage info "$name" 2>/dev/null | grep -E "^(Total|Used):" | awk '{print $2}')
        total=$(echo "$info" | head -1)
        used=$(echo "$info" | tail -1)
        printf "  %-20s (%s)  %s / %s used\n" "$name" "$driver" "${used:-?}" "${total:-?}"
    done
    
    # 实例列表
    echo ""
    echo "实例列表:"
    echo "  NAME                TYPE   STATE    STORAGE POOL"
    incus list -f csv -c ntsPl 2>/dev/null | while IFS=',' read -r name type state pid location; do
        # 获取存储池
        pool=$(incus config device show "$name" 2>/dev/null | grep -A5 "root:" | grep "pool:" | awk '{print $2}')
        printf "  %-20s %-6s %-8s %s\n" "$name" "$type" "$state" "${pool:-default}"
    done
    
    # 检查存储池使用率
    echo ""
    incus storage list -f csv 2>/dev/null | while IFS=',' read -r name driver desc state; do
        info=$(incus storage info "$name" 2>/dev/null)
        total=$(echo "$info" | grep "^Total:" | awk '{print $2}' | sed 's/GiB//')
        used=$(echo "$info" | grep "^Used:" | awk '{print $2}' | sed 's/GiB//')
        if [ -n "$total" ] && [ -n "$used" ]; then
            pct=$(echo "scale=0; $used * 100 / $total" | bc 2>/dev/null || echo "0")
            if [ "$pct" -gt 80 ] 2>/dev/null; then
                echo "⚠️  存储池 $name 使用率超过 80%（${pct}%），建议扩容！"
            fi
        fi
    done
    
    echo "========================================================="
}

# 显示配置
show_lxc_config() {
    echo ""
    echo "当前配置:"
    echo "  1) CPU 核数:        $LXC_CPU"
    echo "  2) CPU 使用率:      $LXC_CPU_ALLOWANCE (仅LXC支持)"
    echo "  3) 内存大小:        $LXC_MEM"
    echo "  4) 硬盘大小:        $LXC_DISK"
    echo "  5) 额外端口数量:    $LXC_PORT_COUNT"
    echo "  6) 带宽限制:        ${LXC_BANDWIDTH:-无限制}"
    echo "  7) 系统镜像:        $LXC_IMAGE"
    echo "  8) 屏蔽CN IP:       $LXC_BLOCK_CN"
}

show_kvm_config() {
    echo ""
    echo "当前配置:"
    echo "  1) CPU 核数:        $KVM_CPU"
    echo "  2) 内存大小:        $KVM_MEM"
    echo "  3) 硬盘大小:        $KVM_DISK"
    echo "  4) 额外端口数量:    $KVM_PORT_COUNT"
    echo "  5) 带宽限制:        ${KVM_BANDWIDTH:-无限制}"
    echo "  6) 系统镜像:        $KVM_IMAGE"
    echo "  7) Secure Boot:     $KVM_SECUREBOOT"
    echo "  8) 屏蔽CN IP:       $KVM_BLOCK_CN"
}

# 修改 LXC 配置
modify_lxc_config() {
    local opt="$1"
    case "$opt" in
        1)
            read -rp "CPU 核数 [$LXC_CPU]: " val
            [ -n "$val" ] && LXC_CPU="$val"
            ;;
        2)
            echo ""
            echo "CPU 使用率配置方式（仅 LXC）:"
            echo "  - 硬限制: 40ms/100ms 表示每100ms最多使用40ms CPU时间（≈40%）"
            echo "  - 软限制: 50% 表示负载高时最多使用50%（空闲时可超）"
            echo "  - 无限制: 留空"
            read -rp "CPU 使用率 [$LXC_CPU_ALLOWANCE]: " val
            LXC_CPU_ALLOWANCE="$val"
            ;;
        3)
            read -rp "内存大小 [$LXC_MEM]: " val
            [ -n "$val" ] && LXC_MEM="$val"
            ;;
        4)
            read -rp "硬盘大小 [$LXC_DISK]: " val
            [ -n "$val" ] && LXC_DISK="$val"
            ;;
        5)
            read -rp "额外端口数量 [$LXC_PORT_COUNT]: " val
            [ -n "$val" ] && LXC_PORT_COUNT="$val"
            ;;
        6)
            echo "带宽限制（如 1000Mbit，留空表示无限制）"
            read -rp "带宽限制 [${LXC_BANDWIDTH:-无限制}]: " val
            LXC_BANDWIDTH="$val"
            ;;
        7)
            read -rp "系统镜像 [$LXC_IMAGE]: " val
            [ -n "$val" ] && LXC_IMAGE="$val"
            ;;
        8)
            read -rp "屏蔽 CN IP (true/false) [$LXC_BLOCK_CN]: " val
            [ -n "$val" ] && LXC_BLOCK_CN="$val"
            ;;
    esac
}

# 修改 KVM 配置
modify_kvm_config() {
    local opt="$1"
    case "$opt" in
        1)
            read -rp "CPU 核数 [$KVM_CPU]: " val
            [ -n "$val" ] && KVM_CPU="$val"
            ;;
        2)
            read -rp "内存大小 [$KVM_MEM]: " val
            [ -n "$val" ] && KVM_MEM="$val"
            ;;
        3)
            read -rp "硬盘大小 [$KVM_DISK]: " val
            [ -n "$val" ] && KVM_DISK="$val"
            ;;
        4)
            read -rp "额外端口数量 [$KVM_PORT_COUNT]: " val
            [ -n "$val" ] && KVM_PORT_COUNT="$val"
            ;;
        5)
            echo "带宽限制（如 1000Mbit，留空表示无限制）"
            read -rp "带宽限制 [${KVM_BANDWIDTH:-无限制}]: " val
            KVM_BANDWIDTH="$val"
            ;;
        6)
            read -rp "系统镜像 [$KVM_IMAGE]: " val
            [ -n "$val" ] && KVM_IMAGE="$val"
            ;;
        7)
            read -rp "Secure Boot (true/false) [$KVM_SECUREBOOT]: " val
            [ -n "$val" ] && KVM_SECUREBOOT="$val"
            ;;
        8)
            read -rp "屏蔽 CN IP (true/false) [$KVM_BLOCK_CN]: " val
            [ -n "$val" ] && KVM_BLOCK_CN="$val"
            ;;
    esac
}

# 创建 LXC 容器
create_lxc() {
    local name="$1"
    local ssh_port="$2"
    local block_cn="$LXC_BLOCK_CN"
    
    local port_start=$((ssh_port + 1))
    local port_end=$((ssh_port + LXC_PORT_COUNT))
    local password
    password="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)"

    echo ""
    echo ">> 1. 创建独立存储池: storage_${name} (${LXC_DISK})..."
    incus storage create "storage_${name}" btrfs size="${LXC_DISK}"

    echo ">> 2. 创建容器: ${name}..."
    local cpu_opts="-c limits.cpu=${LXC_CPU}"
    [ -n "$LXC_CPU_ALLOWANCE" ] && cpu_opts="$cpu_opts -c limits.cpu.allowance=${LXC_CPU_ALLOWANCE}"
    
    incus init "${LXC_IMAGE}" "${name}" \
      $cpu_opts \
      -c limits.memory="${LXC_MEM}" \
      --storage "storage_${name}"

    echo ">> 3. 配置端口映射..."
    incus config device add "${name}" ssh-port proxy listen=tcp:0.0.0.0:${ssh_port} connect=tcp:127.0.0.1:22
    if [ "${LXC_PORT_COUNT}" -gt 0 ]; then
        incus config device add "${name}" nattcp-ports proxy listen=tcp:0.0.0.0:${port_start}-${port_end} connect=tcp:127.0.0.1:${port_start}-${port_end}
        incus config device add "${name}" natudp-ports proxy listen=udp:0.0.0.0:${port_start}-${port_end} connect=udp:127.0.0.1:${port_start}-${port_end}
    fi

    echo ">> 4. 配置资源限制..."
    # 获取网卡设备名（通常是 eth0）
    local nic_name
    nic_name=$(incus config device list "${name}" 2>/dev/null | grep -E "^eth|^nic" | head -1)
    [ -z "$nic_name" ] && nic_name="eth0"

    if [ -n "$LXC_BANDWIDTH" ]; then
        incus config device override "${name}" "$nic_name" limits.egress="${LXC_BANDWIDTH}" limits.ingress="${LXC_BANDWIDTH}"
    fi
    incus config set "${name}" security.nesting=true

    echo ">> 5. 启动容器并配置系统..."
    incus start "${name}"
    
    echo "   等待网络就绪..."
    # 循环检查网络连接（因为容器启动快但网络DHCP可能慢）
    for i in {1..20}; do
        if incus exec "${name}" -- ping -c 1 8.8.8.8 >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done

    echo "   安装并配置 SSH 服务..."
    # 尝试更新源，如果失败重试一次
    if ! incus exec "${name}" -- apt-get update -y >/dev/null 2>&1; then
        sleep 3
        incus exec "${name}" -- apt-get update -y >/dev/null 2>&1
    fi
    
    incus exec "${name}" -- apt-get install -y openssh-server >/dev/null 2>&1
    incus exec "${name}" -- bash -c "echo 'root:${password}' | chpasswd"
    incus exec "${name}" -- sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    incus exec "${name}" -- sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
    incus exec "${name}" -- systemctl restart ssh || incus exec "${name}" -- systemctl restart sshd

    # 保存配置到实例 config，方便删除时读取
    incus config set "${name}" user.ssh_port "${ssh_port}"
    incus config set "${name}" user.port_range "${port_start}-${port_end}"

    if [ "$block_cn" = "true" ]; then
        if check_ipset; then
            block_cn_ports "$ssh_port" "$port_start" "$port_end"
            incus config set "${name}" user.block_cn "true"
        else
            echo "⚠️  无法启用 CN 屏蔽功能"
        fi
    fi

    cat > "${name}.info" << EOF
类型: LXC 容器
名称: ${name}
SSH端口: ${ssh_port}
密码: ${password}
端口范围: ${port_start}-${port_end}
存储池: storage_${name}
CN屏蔽: ${block_cn:-false}
EOF

    echo "=========================================="
    echo "✅ LXC 容器创建成功！"
    echo "SSH: ssh root@宿主机IP -p ${ssh_port}"
    echo "密码: ${password}"
    echo "端口范围: ${port_start}-${port_end}"
    echo "容器信息已保存到: ./${name}.info"
    echo "=========================================="
}

# 创建 KVM 虚拟机
create_kvm() {
    local name="$1"
    local ssh_port="$2"
    local block_cn="$KVM_BLOCK_CN"
    
    local password
    password="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)"

    echo ""
    echo ">> 1. 创建虚拟机: ${name}..."
    incus init "${KVM_IMAGE}" "${name}" --vm \
      -c limits.cpu="${KVM_CPU}" \
      -c limits.memory="${KVM_MEM}" \
      -c security.secureboot="${KVM_SECUREBOOT}" \
      --device root,size="${KVM_DISK}"

    echo ">> 2. 配置资源限制..."
    # 获取网卡设备名（通常是 eth0）
    local nic_name
    nic_name=$(incus config device list "${name}" 2>/dev/null | grep -E "^eth|^nic" | head -1)
    [ -z "$nic_name" ] && nic_name="eth0"
    
    if [ -n "$KVM_BANDWIDTH" ]; then
        incus config device override "${name}" "$nic_name" limits.egress="${KVM_BANDWIDTH}" limits.ingress="${KVM_BANDWIDTH}"
    fi

    echo ">> 3. 启动虚拟机..."
    incus start "${name}"
    
    echo ""
    echo "⏳ 等待虚拟机启动并获取 IP（约 30 秒）..."
    sleep 30
    
    # 获取虚拟机 IP
    local vm_ip
    vm_ip=$(incus list "${name}" -f csv -c 4 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    if [ -z "$vm_ip" ]; then
        echo "⚠️  无法获取虚拟机 IP，尝试等待更长时间..."
        sleep 30
        vm_ip=$(incus list "${name}" -f csv -c 4 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    fi
    
    if [ -z "$vm_ip" ]; then
        echo "❌ 无法获取虚拟机 IP"
        echo "   请使用 VNC 控制台登录配置网络: incus console ${name} --type=vga"
        
        cat > "${name}.info" << EOF
类型: KVM 虚拟机
名称: ${name}
状态: 需要手动配置网络
VNC控制台: incus console ${name} --type=vga
EOF
        echo ""
        echo "==========================================" 
        echo "⚠️  KVM 虚拟机创建完成，但需要手动配置！"
        echo "VNC 控制台: incus console ${name} --type=vga"
        echo "==========================================" 
        return
    fi
    
    echo "   虚拟机 IP: $vm_ip"
    
    echo ">> 4. 配置端口映射..."
    # 获取宿主机 IP
    local host_ip
    host_ip=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
    echo "   宿主机 IP: $host_ip"
    
    # KVM 使用 NAT 模式，需要先在 Incus 配置中设置 VM 的静态 IP
    # 检查设备是否已被覆盖（本地存在），如果不存在则覆盖，如果存在则设置
    if incus config device show "${name}" 2>/dev/null | grep -q "${nic_name}:"; then
         incus config device set "${name}" "$nic_name" ipv4.address="${vm_ip}"
    else
         incus config device override "${name}" "$nic_name" ipv4.address="${vm_ip}"
    fi
    
    # 然后配置端口映射
    incus config device add "${name}" ssh-port proxy listen=tcp:${host_ip}:${ssh_port} connect=tcp:${vm_ip}:22 nat=true
    
    echo ">> 5. 配置 SSH..."
    echo "   等待 incus-agent 启动..."
    # 循环检查 agent 是否就绪（最多等待 60 秒）
    local agent_ready=0
    for i in {1..20}; do
        if incus exec "${name}" -- uptime >/dev/null 2>&1; then
            agent_ready=1
            break
        fi
        sleep 3
    done
    
    if [ "$agent_ready" -eq 0 ]; then
        echo "⚠️  incus-agent 未就绪，无法自动配置 SSH"
        echo "   请通过 VNC 控制台手动安装 SSH 服务"
    else
        echo "   安装并配置 SSH 服务..."
        incus exec "${name}" -- apt-get update -y >/dev/null 2>&1
        incus exec "${name}" -- apt-get install -y openssh-server >/dev/null 2>&1
        incus exec "${name}" -- bash -c "echo 'root:${password}' | chpasswd"
        incus exec "${name}" -- sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        incus exec "${name}" -- sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
        incus exec "${name}" -- systemctl restart ssh || incus exec "${name}" -- systemctl restart sshd
    fi

    # 保存配置到实例 config
    # KVM 端口范围计算逻辑相同：start = ssh + 1, end = ssh + count
    local port_start=$((ssh_port + 1))
    local port_end=$((ssh_port + KVM_PORT_COUNT))
    incus config set "${name}" user.ssh_port "${ssh_port}"
    incus config set "${name}" user.port_range "${port_start}-${port_end}"

    if [ "$block_cn" = "true" ]; then
        if check_ipset; then
            block_cn_ports "$ssh_port" "$port_start" "$port_end"
            incus config set "${name}" user.block_cn "true"
        else
             echo "⚠️  无法启用 CN 屏蔽功能"
        fi
    fi

    cat > "${name}.info" << EOF
类型: KVM 虚拟机
名称: ${name}
虚拟机IP: ${vm_ip}
SSH端口: ${ssh_port}
密码: ${password}
VNC控制台: incus console ${name} --type=vga
注意: KVM 端口范围转发较复杂，建议直接使用虚拟机 IP
CN屏蔽: ${block_cn:-false}
EOF

    echo "=========================================="
    echo "✅ KVM 虚拟机创建成功！"
    echo "SSH: ssh root@${host_ip} -p ${ssh_port}"
    echo "密码: ${password}"
    echo "虚拟机 IP: ${vm_ip}"
    echo "VNC 控制台: incus console ${name} --type=vga"
    echo ""
    echo "ℹ️  KVM 端口范围转发较复杂，建议直接使用虚拟机内网 IP"
    echo "容器信息已保存到: ./${name}.info"
    echo "=========================================="
}

# 交互式创建
do_create() {
    check_root
    check_ephemeral_ports
    local name="$1"
    local ssh_port="$2"
    
    if [ -z "$name" ]; then
        read -rp "请输入实例名称: " name
    fi
    
    if [ -z "$ssh_port" ]; then
        read -rp "请输入 SSH 端口 (20000-55000): " ssh_port
    fi
    
    if [ -z "$name" ] || [ -z "$ssh_port" ]; then
        echo "Error: 名称和端口不能为空"
        exit 1
    fi

    # 校验端口范围（20000-55000，留出9999端口余量）
    if [ "$ssh_port" -lt 20000 ] || [ "$ssh_port" -gt 55000 ] 2>/dev/null; then
        echo "Error: SSH 端口必须在 20000-55000 范围内"
        echo "  - 10000-19999 为系统临时端口"
        echo "  - 10000 以下为常用应用端口"
        echo "  - 55000+ 需要留给端口范围（+9999）"
        exit 1
    fi

    if incus info "$name" >/dev/null 2>&1; then
        echo "Error: 实例 $name 已存在"
        exit 1
    fi

    echo "==================== Incus 实例创建 ===================="
    echo "请选择实例类型:"
    echo "  1) LXC 容器 - 轻量级，共享内核，资源消耗低"
    echo "  2) KVM 虚拟机 - 完全隔离，独立内核，适合生产环境"
    echo ""
    read -rp "请选择 [1/2]: " type_choice

    if [ "$type_choice" = "2" ]; then
        # KVM
        echo ""
        echo "==================== 创建 KVM 虚拟机 ===================="
        echo "虚拟机名称: $name"
        echo "SSH 端口: $ssh_port"
        
        while true; do
            show_kvm_config
            echo ""
            read -rp "输入要修改的选项编号（回车继续）: " opt
            if [ -z "$opt" ]; then
                break
            fi
            modify_kvm_config "$opt"
        done
        
        echo ""
        read -rp "确认创建 KVM 虚拟机？[Y/n] " confirm
        if [ "$confirm" != "n" ] && [ "$confirm" != "N" ]; then
            # 检查端口
            if ! check_ports "$ssh_port" "$KVM_PORT_COUNT"; then
                exit 1
            fi
            create_kvm "$name" "$ssh_port"
        else
            echo "已取消"
        fi
    else
        # LXC
        echo ""
        echo "==================== 创建 LXC 容器 ===================="
        echo "容器名称: $name"
        echo "SSH 端口: $ssh_port"
        
        while true; do
            show_lxc_config
            echo ""
            read -rp "输入要修改的选项编号（回车继续）: " opt
            if [ -z "$opt" ]; then
                break
            fi
            modify_lxc_config "$opt"
        done
        
        echo ""
        read -rp "确认创建 LXC 容器？[Y/n] " confirm
        if [ "$confirm" != "n" ] && [ "$confirm" != "N" ]; then
            # 检查端口
            if ! check_ports "$ssh_port" "$LXC_PORT_COUNT"; then
                exit 1
            fi
            create_lxc "$name" "$ssh_port"
        else
            echo "已取消"
        fi
    fi
}

# 删除实例
do_delete() {
    check_root
    local name="$1"
    
    if [ -z "$name" ]; then
        read -rp "请输入要删除的实例名称: " name
    fi
    
    if [ -z "$name" ]; then
        echo "Error: 实例名称不能为空"
        exit 1
    fi

    if ! incus info "$name" >/dev/null 2>&1; then
        echo "Error: 实例 $name 不存在"
        exit 1
    fi

    # 获取实例类型
    local inst_type
    inst_type=$(incus info "$name" 2>/dev/null | grep "^Type:" | awk '{print $2}')
    # 转换为易读格式
    case "$inst_type" in
        container) inst_type="LXC 容器" ;;
        virtual-machine) inst_type="KVM 虚拟机" ;;
    esac
    
    # 检查是否有独立存储池
    local pool="storage_${name}"
    local has_pool="否"
    if incus storage show "$pool" >/dev/null 2>&1; then
        has_pool="是（将一并删除）"
    fi
    
    echo ""
    echo "==================== 删除确认 ===================="
    echo "实例名称: $name"
    echo "实例类型: $inst_type"
    echo "独立存储池: $has_pool"
    echo "================================================="
    echo ""
    read -rp "⚠️  确认删除此实例？此操作不可恢复！[y/N] " confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "已取消"
        exit 0
    fi

    echo ""
    echo ">> 停止并删除实例 $name ..."
    incus stop "$name" --force 2>/dev/null || true
    
    # 检查是否启用了 CN 屏蔽
    local is_blocked
    is_blocked=$(incus config get "$name" user.block_cn 2>/dev/null || echo "false")
    
    if [ "$is_blocked" = "true" ]; then
        local ssh_p
        ssh_p=$(incus config get "$name" user.ssh_port 2>/dev/null)
        local range_p
        range_p=$(incus config get "$name" user.port_range 2>/dev/null)
        
        if [ -n "$ssh_p" ] && [ -n "$range_p" ]; then
            # 解析范围
            local p_start p_end
            p_start=$(echo "$range_p" | cut -d'-' -f1)
            p_end=$(echo "$range_p" | cut -d'-' -f2)
            unblock_cn_ports "$ssh_p" "$p_start" "$p_end"
        fi
    fi
    
    incus delete "$name"

    # 删除独立存储池（如果存在）
    if incus storage show "$pool" >/dev/null 2>&1; then
        echo ">> 删除独立存储池 $pool ..."
        incus storage delete "$pool"
    fi

    rm -f "${name}.info" "${name}" "${name}_v6"
    echo "✅ 删除完成！"
}

# 主菜单
main_menu() {
    check_root
    echo "==================== Incus 管理脚本 ===================="
    echo "1. 创建实例 (Create)"
    echo "2. 删除实例 (Delete)"
    echo "3. 查看状态 (Status)"
    echo "0. 退出 (Exit)"
    echo "========================================================"
    read -rp "请输入选项 [0-3]: " choice
    case "$choice" in
        1) do_create ;;
        2) do_delete ;;
        3) do_status ;;
        0) exit 0 ;;
        *) echo "无效选项"; exit 1 ;;
    esac
}

# 主入口
if [ $# -eq 0 ]; then
    main_menu
    exit 0
fi

case "$1" in
    create)
        do_create "$2" "$3"
        ;;
    delete)
        do_delete "$2"
        ;;
    status)
        do_status
        ;;
    *)
        echo "Incus 统一管理脚本"
        echo ""
        echo "用法:"
        echo "  bash incus_manage.sh                        # 进入交互式菜单"
        echo "  bash incus_manage.sh create <名称> <SSH端口> # 命令行创建"
        echo "  bash incus_manage.sh delete <名称>           # 命令行删除"
        echo "  bash incus_manage.sh status                  # 查看状态"
        exit 1
        ;;
esac
