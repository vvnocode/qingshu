#!/bin/bash
# =============================================================================
# 端口限速脚本 (Port Speed Limiter)
# 使用 Linux tc (traffic control) 实现入站端口的上传/下载速度限制
# 
# 作者: vv 2026/01/13
# 
# 用法: 
#   应用配置: ./port_speed_limiter.sh apply [配置文件路径]
#   编辑配置: ./port_speed_limiter.sh edit
#   查看状态: ./port_speed_limiter.sh status
#   清除所有: ./port_speed_limiter.sh clear
#   开机自启: ./port_speed_limiter.sh install
#   
# 默认配置文件路径: ./config.conf
# 
# 配置文件格式 (每行一个端口):
#   端口 下载速度 上传速度
#   
# 速度单位 (支持以下格式, 不区分大小写):
#   Mbps/mbps - 兆比特每秒, 例如: 10Mbps ≈ 1.25 MB/s
#   Kbps/kbps - 千比特每秒, 例如: 500Kbps ≈ 62.5 KB/s
#   0         - 不限制
# 
# 配置示例:
#   443 10Mbps 5Mbps      # 443端口: 下载 10 Mbps, 上传 5 Mbps
#   8080 0 2Mbps          # 8080端口: 下载不限制, 上传 2 Mbps
#   9999 500Kbps 0        # 9999端口: 下载 500 Kbps, 上传不限制
# =============================================================================

set -e

# 配置
CONFIG_DIR="."
DEFAULT_CONFIG_FILE="${CONFIG_DIR}/config.conf"
STATE_FILE="${CONFIG_DIR}/state.conf"
INTERFACE=""  # 自动检测

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "$DEBUG" == "1" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要 root 权限运行"
        exit 1
    fi
}

# 自动检测网络接口
detect_interface() {
    # 优先使用默认路由的接口
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$INTERFACE" ]]; then
        # 备选方案：查找第一个非回环接口
        INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)
    fi
    
    if [[ -z "$INTERFACE" ]]; then
        log_error "无法检测到网络接口"
        exit 1
    fi
    
    log_info "检测到网络接口: $INTERFACE"
}

# 初始化配置目录
init_config() {
    mkdir -p "$CONFIG_DIR"
    
    # 如果默认配置文件不存在，创建示例配置
    if [[ ! -f "$DEFAULT_CONFIG_FILE" ]]; then
        cat > "$DEFAULT_CONFIG_FILE" << 'EOF'
# 端口限速配置文件
# 
# 格式: 端口 下载速度 上传速度
# 
# 速度单位 (不区分大小写):
#   Mbps - 兆比特每秒, 例如: 10Mbps ≈ 1.25 MB/s
#   Kbps - 千比特每秒, 例如: 500Kbps ≈ 62.5 KB/s
#   0    - 不限制
# 
# 方向说明:
#   下载速度: 服务器 -> 用户 (服务器出站流量)
#   上传速度: 用户 -> 服务器 (服务器入站流量)
#
# 注释以 # 开头，空行会被忽略
# =============================================================

# 在下面添加你的端口限速配置:
# 443 10Mbps 5Mbps   # 下载 10 Mbps, 上传 5 Mbps
# 8080 0 2Mbps       # 下载不限制, 上传 2 Mbps
# 9999 500Kbps 0     # 下载 500 Kbps, 上传不限制

EOF
        log_info "已创建默认配置文件: $DEFAULT_CONFIG_FILE"
    fi
}

# 解析配置文件
parse_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        exit 1
    fi
    
    # 读取并解析配置文件，过滤注释和空行
    grep -v '^\s*#' "$config_file" | grep -v '^\s*$' | while read -r line; do
        echo "$line"
    done
}

# 清除所有 tc 规则
clear_tc() {
    log_info "清除现有 tc 规则..."
    
    # 清除主接口的 tc 规则
    tc qdisc del dev "$INTERFACE" root 2>/dev/null || true
    tc qdisc del dev "$INTERFACE" ingress 2>/dev/null || true
    
    # 清除 IFB 设备的规则
    tc qdisc del dev ifb0 root 2>/dev/null || true
    ip link set dev ifb0 down 2>/dev/null || true
    
    # 清除 iptables mangle 表中的限速标记规则
    log_info "清除 iptables mangle 规则..."
    iptables -t mangle -F PREROUTING 2>/dev/null || true
    iptables -t mangle -F POSTROUTING 2>/dev/null || true
    
    # 清除状态文件
    rm -f "$STATE_FILE" 2>/dev/null || true
    
    log_info "所有限速规则已清除"
}

# 初始化 tc qdisc
init_tc() {
    log_info "初始化 tc qdisc..."
    
    # 先清除可能存在的旧规则
    tc qdisc del dev "$INTERFACE" root 2>/dev/null || true
    tc qdisc del dev "$INTERFACE" ingress 2>/dev/null || true
    
    # 添加 egress (出站/下载) 的 htb qdisc
    tc qdisc add dev "$INTERFACE" root handle 1: htb default 999
    # 添加默认类，不限速 (10 Gbps 上限)
    tc class add dev "$INTERFACE" parent 1: classid 1:999 htb rate 10gbit
    
    # 添加 ingress qdisc 用于入站/上传限速
    tc qdisc add dev "$INTERFACE" ingress handle ffff:
    
    log_info "tc qdisc 初始化完成"
}

# 速度单位转换: 支持 Mbps/mbps/Kbps/kbps -> mbit/kbit (tc 格式)
convert_rate() {
    local rate=$1
    # 转换为小写处理
    local lower_rate=$(echo "$rate" | tr '[:upper:]' '[:lower:]')
    
    # Mbps/mbps -> mbit
    if [[ "$lower_rate" =~ ^([0-9]+)mbps$ ]]; then
        echo "${BASH_REMATCH[1]}mbit"
    # Kbps/kbps -> kbit
    elif [[ "$lower_rate" =~ ^([0-9]+)kbps$ ]]; then
        echo "${BASH_REMATCH[1]}kbit"
    # 已经是 mbit/kbit 格式，直接返回
    elif [[ "$lower_rate" =~ ^([0-9]+)(m|k)bit$ ]]; then
        echo "$lower_rate"
    else
        # 未知格式，原样返回
        echo "$rate"
    fi
}

# 添加单个端口的限速规则
add_port_limit() {
    local port=$1
    local download_rate_raw=$2  # 下载速度 (服务器 -> 用户)
    local upload_rate_raw=$3    # 上传速度 (用户 -> 服务器)
    local class_id=$4
    local mark=$class_id    # 使用 class_id 作为 iptables mark
    
    # 转换速度单位
    local download_rate=$(convert_rate "$download_rate_raw")
    local upload_rate=$(convert_rate "$upload_rate_raw")
    
    # 显示限速信息
    local dl_display="$download_rate"
    local ul_display="$upload_rate"
    [[ "$download_rate" == "0" ]] && dl_display="不限制"
    [[ "$upload_rate" == "0" ]] && ul_display="不限制"
    log_info "添加端口 $port 限速: 下载 $dl_display, 上传 $ul_display (class_id: $class_id)"
    
    # ==================== 下载限制 (服务器 -> 用户) ====================
    if [[ "$download_rate" != "0" ]]; then
        # 标记出站流量 (服务器 -> 用户, 源端口)
        iptables -t mangle -A POSTROUTING -p tcp --sport $port -j MARK --set-mark $mark 2>/dev/null || true
        iptables -t mangle -A POSTROUTING -p udp --sport $port -j MARK --set-mark $mark 2>/dev/null || true
        
        # 在主接口上使用 HTB + fw 过滤器
        tc class add dev "$INTERFACE" parent 1: classid 1:$class_id htb rate $download_rate ceil $download_rate
        tc qdisc add dev "$INTERFACE" parent 1:$class_id handle $class_id: sfq perturb 10
        tc filter add dev "$INTERFACE" protocol ip parent 1: prio $class_id handle $mark fw flowid 1:$class_id
    fi
    
    # ==================== 上传限制 (用户 -> 服务器) ====================
    if [[ "$upload_rate" != "0" ]]; then
        # 使用 ingress qdisc + police 直接限制入站流量
        # TCP
        tc filter add dev "$INTERFACE" parent ffff: protocol ip prio $class_id u32 \
            match ip protocol 6 0xff \
            match ip dport $port 0xffff \
            police rate $upload_rate burst 64k drop \
            flowid :$class_id
        
        # UDP
        tc filter add dev "$INTERFACE" parent ffff: protocol ip prio $class_id u32 \
            match ip protocol 17 0xff \
            match ip dport $port 0xffff \
            police rate $upload_rate burst 64k drop \
            flowid :$class_id
    fi
    
    # 记录到状态文件
    echo "${port}:${class_id}:${download_rate}:${upload_rate}" >> "$STATE_FILE"
}

# 应用配置文件
apply_config() {
    local config_file="${1:-$DEFAULT_CONFIG_FILE}"
    
    log_info "应用配置文件: $config_file"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        log_info "请创建配置文件或使用示例: $DEFAULT_CONFIG_FILE"
        exit 1
    fi
    
    # 初始化 tc
    init_tc
    
    # 初始化状态文件
    echo "# 自动生成，请勿手动修改" > "$STATE_FILE"
    echo "# 格式: 端口:class_id:下载速度:上传速度" >> "$STATE_FILE"
    
    # 读取配置并应用
    local class_id=10
    local count=0
    
    # 使用 || [[ -n "$line" ]] 确保能读取没有换行符结尾的最后一行
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 跳过注释和空行
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # 解析行: 端口 下载速度 上传速度
        read -r port download upload <<< "$line"
        
        if [[ -n "$port" && -n "$download" && -n "$upload" ]]; then
            add_port_limit "$port" "$download" "$upload" "$class_id"
            ((class_id++))
            ((count++))
        else
            log_warn "跳过无效配置行: $line"
        fi
    done < "$config_file"
    
    if [[ $count -eq 0 ]]; then
        log_warn "配置文件中没有有效的限速规则"
        log_info "请编辑配置文件添加规则: $config_file"
    else
        log_info "成功应用 $count 条限速规则"
    fi
}

# 显示当前状态
show_status() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              端口限速状态                            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}【网络接口】${NC} $INTERFACE"
    echo ""
    
    echo -e "${CYAN}【配置的端口限速】${NC}"
    if [[ -f "$STATE_FILE" ]] && grep -v '^#' "$STATE_FILE" | grep -q .; then
        echo ""
        printf "  ${YELLOW}%-10s %-12s %-12s %-12s${NC}\n" "端口" "Class ID" "下载限制" "上传限制"
        printf "  %-10s %-12s %-12s %-12s\n" "─────" "──────────" "──────────" "──────────"
        grep -v '^#' "$STATE_FILE" | while IFS=':' read -r port class_id download upload; do
            if [[ -n "$port" ]]; then
                printf "  %-10s %-12s %-12s %-12s\n" "$port" "$class_id" "$download" "$upload"
            fi
        done
    else
        echo "  暂无限速规则"
    fi
    
    echo ""
    echo -e "${CYAN}【配置文件】${NC}"
    echo "  $DEFAULT_CONFIG_FILE"
    
    echo ""
    echo -e "${CYAN}【TC 规则详情】${NC}"
    echo ""
    echo "  主接口 ($INTERFACE) 类 (下载/出站):"
    tc class show dev "$INTERFACE" 2>/dev/null | sed 's/^/    /' || echo "    无规则"
    
    echo ""
    echo "  IFB0 类 (上传/入站):"
    tc class show dev ifb0 2>/dev/null | sed 's/^/    /' || echo "    无规则"
    
    echo ""
}

# 安装为系统服务
install_service() {
    local script_path=$(readlink -f "$0")
    
    log_info "安装 systemd 服务..."
    
    cat > /etc/systemd/system/port-limiter.service << EOF
[Unit]
Description=Port Speed Limiter
After=network.target

[Service]
Type=oneshot
ExecStart=$script_path apply
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable port-limiter.service
    
    log_info "服务安装完成！"
    log_info "使用以下命令管理服务:"
    echo "  启动: systemctl start port-limiter"
    echo "  停止: systemctl stop port-limiter"
    echo "  状态: systemctl status port-limiter"
    echo ""
    log_info "服务将在系统启动时自动应用限速规则"
}

# 卸载系统服务
uninstall_service() {
    log_info "卸载 systemd 服务..."
    
    systemctl stop port-limiter.service 2>/dev/null || true
    systemctl disable port-limiter.service 2>/dev/null || true
    rm -f /etc/systemd/system/port-limiter.service
    systemctl daemon-reload
    
    log_info "服务已卸载"
}

# 编辑配置文件
edit_config() {
    local editor="${EDITOR:-nano}"
    
    if ! command -v "$editor" &> /dev/null; then
        editor="vi"
    fi
    
    log_info "使用 $editor 编辑配置文件..."
    $editor "$DEFAULT_CONFIG_FILE"
    
    echo ""
    read -p "是否立即应用新配置? [Y/n] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        apply_config
    fi
}

# 显示帮助
show_help() {
    echo ""
    echo -e "${GREEN}端口限速脚本 (Port Speed Limiter)${NC}"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  apply [配置文件]    应用配置文件中的限速规则"
    echo "  status              查看当前限速状态"
    echo "  clear               清除所有限速规则"
    echo "  edit                编辑配置文件"
    echo "  install             安装为 systemd 服务 (开机自启)"
    echo "  uninstall           卸载 systemd 服务"
    echo "  help                显示此帮助信息"
    echo ""
    echo "配置文件:"
    echo "  默认路径: $DEFAULT_CONFIG_FILE"
    echo ""
    echo "配置格式 (每行一个):"
    echo "  端口 下载速度 上传速度"
    echo ""
    echo "速度单位 (不区分大小写):"
    echo "  Mbps - 兆比特每秒, 例如: 10Mbps ≈ 1.25 MB/s"
    echo "  Kbps - 千比特每秒, 例如: 500Kbps ≈ 62.5 KB/s"
    echo "  0    - 不限制"
    echo ""
    echo "示例配置:"
    echo "  443 10Mbps 5Mbps   # 下载 10 Mbps, 上传 5 Mbps"
    echo "  8080 0 2Mbps       # 下载不限制, 上传 2 Mbps"
    echo "  9999 500Kbps 0     # 下载 500 Kbps, 上传不限制"
    echo ""
    echo "方向说明:"
    echo "  下载速度: 服务器 -> 用户 (服务器出站流量)"
    echo "  上传速度: 用户 -> 服务器 (服务器入站流量)"
    echo ""
}

# 主程序
main() {
    case "$1" in
        apply)
            check_root
            detect_interface
            init_config
            apply_config "$2"
            ;;
        status|show)
            check_root
            detect_interface
            init_config
            show_status
            ;;
        clear|clean|reset)
            check_root
            detect_interface
            clear_tc
            ;;
        edit)
            check_root
            detect_interface
            init_config
            edit_config
            ;;
        install)
            check_root
            install_service
            ;;
        uninstall)
            check_root
            uninstall_service
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            ;;
    esac
}

main "$@"
