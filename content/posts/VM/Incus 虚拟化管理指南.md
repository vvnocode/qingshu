---
title: "Incus 虚拟化管理指南"
date: 2026-01-22T12:38:31+08:00
draft: false
tags: ["Incus", "LXC", "KVM"]
categories: ["VM"]
---

> 本文档介绍如何使用 Incus 创建和管理 LXC 容器与 KVM 虚拟机（俗称"开小鸡"），适合初学者快速上手。
> by easter

## 目录

- [推荐开源项目](#推荐开源项目)
- [前置知识](#前置知识)
- [安装 Incus](#安装-incus)
- [创建实例](#创建实例)
  - [使用统一管理脚本（推荐）](#使用统一管理脚本推荐)
  - [手动创建](#手动创建)
- [常用命令](#常用命令)
- [维护与管理](#维护与管理)
- [故障排查](#故障排查)
- [参考资料](#参考资料)

---

## 推荐开源项目

### oneclickvirt/incus（强烈推荐）

这是目前最成熟、最活跃的 Incus 一键开 LXC 项目，由 SpiritLHL 维护。

**项目特点：**
- 🚀 一键安装 Incus 环境
- 📦 单独/批量创建 NAT 容器
- 🎯 自动配置 CPU、内存、硬盘、带宽限制
- 🌐 自动配置端口映射（SSH + 自定义端口范围）
- 💾 支持多种 Linux 发行版镜像
- 🔧 持续更新维护（2025年仍在活跃更新）

**相关链接：**
- GitHub: https://github.com/oneclickvirt/incus
- 文档（中文）: https://www.spiritlhl.net/guide/incus/incus_lxc.html
- 文档（英文）: https://www.spiritlhl.net/en/
- 自编译镜像源: https://github.com/oneclickvirt/incus_images
- Telegram 群组: https://t.me/oneclickvirt

### 其他相关项目

| 项目 | 说明 |
|------|------|
| [Distrobuilder](https://github.com/lxc/distrobuilder) | LXC 官方镜像构建工具 |
| [IncusOS](https://linuxcontainers.org/incusos/) | 专为运行 Incus 设计的不可变操作系统 |
| [Incus Terraform Provider](https://registry.terraform.io/providers/lxc/incus/) | 基础设施即代码支持 |

---

## 前置知识

### Incus 是什么？

Incus 是一个开源的系统容器和虚拟机管理器，是 LXD 的社区驱动分支。它可以：
- 运行 **系统容器**（LXC）：隔离的 Linux 系统，共享宿主机内核
- 运行 **虚拟机**（KVM/QEMU）：完全虚拟化，独立内核

### LXC vs Docker vs KVM

| 特性 | LXC 系统容器 | Docker 应用容器 | KVM 虚拟机 |
|------|------------|---------------|------------|
| 隔离级别 | 操作系统级 | 应用级 | 硬件级 |
| 资源消耗 | 低 | 很低 | 高 |
| 启动速度 | 秒级 | 秒级 | 分钟级 |
| 内核共享 | 是 | 是 | 否 |
| 磁盘限制 | 依赖 btrfs/zfs 配额 | 依赖存储驱动 | 虚拟磁盘文件（精确） |
| 适用场景 | VPS/开发环境 | 微服务部署 | 生产/高隔离需求 |

### LXC vs KVM 配置差异

| 配置项 | LXC 容器 | KVM 虚拟机 | 说明 |
|--------|:--------:|:----------:|------|
| CPU 数量 | ✅ | ✅ | `limits.cpu=2` |
| CPU 使用率 | ✅ | ❌ | `limits.cpu.allowance`（仅 LXC） |
| CPU 优先级 | ✅ | ✅ | `limits.cpu.priority=5` |
| 内存 | ✅ | ✅ | `limits.memory=1GB` |
| 磁盘 | 独立存储池 | 虚拟磁盘文件 | KVM 无共享存储池问题 |
| Secure Boot | ❌ | ✅ | `security.secureboot=true` |
| TPM | ❌ | ✅ | `security.tpm=true`（Windows 11 需要） |
| VNC 控制台 | ❌ | ✅ | 图形界面访问 |

### LXC 的局限性

> [!WARNING]
> LXC 容器不支持以下操作（因为共享宿主机内核）：
> - 更换内核
> - DD 重装系统
> - 开启 BBR 加速
> - 挂载某些内核模块

### KVM 的前置要求

> [!NOTE]
> KVM 虚拟机需要宿主机支持硬件虚拟化（VT-x/AMD-V）。

```bash
# 检查是否支持硬件虚拟化
grep -E '(vmx|svm)' /proc/cpuinfo

# 检查 /dev/kvm 是否可用
ls -la /dev/kvm
```

如果在 VPS 上运行，需要确认 VPS 提供商开启了嵌套虚拟化。

---

## 安装 Incus

### 使用 oneclickvirt 一键脚本（强烈推荐）

该脚本会自动完成以下工作：
- 安装 Incus
- 配置存储池（名为 `default` 的 btrfs 存储池）
- 配置网络
- 下载容器创建脚本

```bash
# 国际线路
curl -L https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/incus_install.sh -o incus_install.sh && chmod +x incus_install.sh && bash incus_install.sh

# 国内线路
curl -L https://cdn.spiritlhl.net/https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/incus_install.sh -o incus_install.sh && chmod +x incus_install.sh && bash incus_install.sh
```

> [!WARNING]
> 如果一键脚本提示：
> ```
> 无法加载btrfs模块。请重启本机再次执行本脚本以加载btrfs内核。
> btrfs module could not be loaded. Please reboot the machine and execute this script again.
> ```
> 
> **请重启服务器后重新运行该脚本，该脚本会继续创建默认存储池**：
> ```bash
> bash incus_install.sh
> ```
> 
> 如果脚本仍然失败，或需要手动配置，先检查存储池是否已存在：
> ```bash
> incus storage list   # 如果已有 default 存储池，跳过创建步骤
> ```
> 
> **手动创建 default 存储池**（如果不存在）：
> 
> `default` 存储池用于存放公共系统镜像（如 Debian、Ubuntu 模板），是所有容器共用的只读模板库。
> 
> ```bash
> # 1. 创建 default 存储池（存放公共镜像，5GB 足够）
> incus storage create default btrfs size=5GB
> 
> # 2. 配置为默认存储池
> incus profile device add default root disk pool=default path=/
> 
> # 3. 创建网络
> incus network create incusbr0
> 
> # 4. 将网络附加到默认 profile
> incus profile device add default eth0 nic network=incusbr0
> ```

安装完成后，即可直接使用下面方式创建实例。

> [!NOTE]- 手动安装（高级用户）
> 
> 参考 [Hentioe 的安装教程](https://blog.hentioe.dev/posts/incus-usage.html)：
> 
> ```bash
> # Debian 第三方安装脚本
> bash <(curl -Ls https://raw.githubusercontent.com/Hentioe/server-helpers/refs/heads/main/debian-install-incus)
> 
> # 初始化 Incus
> incus admin init
> ```
> 
> 初始化时的建议配置：
> - 存储池：创建名为 `default` 的 btrfs 存储池
> - 网络：使用默认配置即可
> - 其他选项：保持默认
> 
> **手动配置存储池：**
> 
> 如果使用 oneclickvirt 脚本，存储池**必须命名为 `default`**。
> 
> ```bash
> # 安装 btrfs 工具
> apt update && apt install btrfs-progs -y
> 
> # 创建 btrfs 存储池
> incus storage create default btrfs size=50GB
> 
> # 配置为默认存储池
> incus profile device add default root disk pool=default path=/
> 
> # 启用 btrfs 配额
> btrfs quota enable /var/lib/incus/storage-pools/default/
> ```
> 
> **ZFS 存储池（大规模使用）：**
> 
> ```bash
> apt install zfsutils-linux -y
> incus storage create default zfs size=100GB
> incus profile device add default root disk pool=default path=/
> ```

---

## 创建实例

### 支持的系统镜像

| 发行版 | 支持版本 |
|--------|---------|
| Debian | 10, 11, 12, 13 |
| Ubuntu | 18, 20, 22, 24 |
| CentOS | 8, 9（Stream 版本） |
| Alpine | 3.15, 3.16, 3.17, 3.18, 3.19 |
| Fedora | 37, 38, 39, 40 |
| Rocky Linux | 8, 9 |
| Oracle Linux | 7, 8, 9 |
| Kali | 最新版 |
| Arch Linux | 最新版 |

> 完整镜像列表参考：[x86_64](https://github.com/oneclickvirt/incus_images/blob/main/x86_64_all_images.txt) | [arm64](https://github.com/oneclickvirt/incus_images/blob/main/arm64_all_images.txt)

### 使用统一管理脚本（推荐）

我们提供 `incus_manage.sh` 统一管理脚本，支持交互式创建 LXC 容器和 KVM 虚拟机。

**功能特点：**
- 交互式选择实例类型（LXC/KVM）
- 显示当前配置，支持逐个修改参数
- 显示存储状态和扩容提示
- 自动清理存储池（删除时）
- 支持屏蔽中国大陆 IP 访问（可选）

#### 方式一：一键运行（推荐）

无需下载文件，直接在服务器上运行以下命令即可：

```bash
# 1. 进入交互式菜单（推荐）
bash <(curl -sL https://intno.de/scripts/incus_manage.sh)

# 2. 命令行快速创建
bash <(curl -sL https://intno.de/scripts/incus_manage.sh) create <名称> <SSH端口>

# 示例
bash <(curl -sL https://intno.de/scripts/incus_manage.sh) create user1 20000

# 查看状态
bash <(curl -sL https://intno.de/scripts/incus_manage.sh) status

# 删除实例
bash <(curl -sL https://intno.de/scripts/incus_manage.sh) delete user1
```

#### 方式二：手动创建脚本

如果无法连接网络，或者需要审查代码，可以将 `https://intno.de/scripts/incus_manage.sh` 保存为 `incus_manage.sh`。

运行方式：

```bash
chmod +x incus_manage.sh

# 交互式创建（会询问选择 LXC 还是 KVM）
./incus_manage.sh create user1 20000

# 查看存储状态
./incus_manage.sh status

# 删除实例
./incus_manage.sh delete user1
```

> [!NOTE]- 使用 oneclickvirt 一键脚本（LXC 专用，共享存储模式）
> 
> 此脚本**仅支持创建 LXC 容器**（`ct` = container）。如果不需要严格的硬盘限制，可以使用 oneclickvirt 的 `buildct.sh` 脚本。它使用共享的 `default` 存储池。
> 
> **下载脚本：**
> ```bash
> curl -L https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/buildct.sh -o buildct.sh && chmod +x buildct.sh
> ```
> 
> **使用方法：**
> ```bash
> # 用法
> ./buildct.sh 容器名称 CPU核数 内存(MB) 硬盘(GB) SSH端口 外网起端口 外网止端口 下载速度(Mbit) 上传速度(Mbit) 是否启用IPv6(Y/N) 系统
> 
> # 示例
> ./buildct.sh myserver 1 512 5 20001 20002 20100 1000 1000 N debian13
> ```
> 
> **查看容器信息：**
> ```bash
> cat myserver   # 单个容器
> cat log        # 批量创建的所有容器
> ```
> 
> **注意**：此模式下硬盘限制可能不精确，删除容器时无需删除存储池。

### 手动创建

#### 手动创建 LXC 容器

```bash
# 创建容器
incus init images:debian/13 mycontainer

# 配置资源限制
incus config set mycontainer limits.cpu=1
incus config set mycontainer limits.cpu.allowance=40ms/100ms
incus config set mycontainer limits.memory=512MiB

# 配置端口映射
incus config device add mycontainer ssh-port proxy listen=tcp:0.0.0.0:20000 connect=tcp:127.0.0.1:22

# 启动
incus start mycontainer

# 进入容器配置 SSH
incus exec mycontainer -- bash
```

#### 手动创建 KVM 虚拟机

```bash
# 创建虚拟机（注意 --vm 参数和磁盘大小）
incus init images:debian/13 myvm --vm --device root,size=20GiB

# 配置资源限制
incus config set myvm limits.cpu=2
incus config set myvm limits.memory=2GB

# 配置端口映射
incus config device add myvm ssh-port proxy listen=tcp:0.0.0.0:20000 connect=tcp:127.0.0.1:22

# 启动
incus start myvm

# 访问 VGA 控制台（图形界面）
incus console myvm --type=vga

# 访问串口控制台
incus console myvm
```

---

## 常用命令

### 实例管理

```bash
# 列出所有实例（容器 + 虚拟机）
incus list

# 查看实例详情
incus info myserver

# 启动/停止/重启
incus start myserver
incus stop myserver
incus restart myserver

# 强制停止
incus stop myserver --force

# 删除实例
incus delete myserver
incus delete myserver --force

# 进入实例
incus exec myserver -- /bin/bash
incus exec myserver -- /bin/sh  # Alpine

# 在实例中执行命令
incus exec myserver -- apt update
```

### 控制台访问（KVM）

```bash
# 串口控制台
incus console myvm

# VGA/VNC 控制台（图形界面）
incus console myvm --type=vga

# 退出控制台: Ctrl+A 然后按 Q
```

### 配置管理

#### 1. 通用配置（LXC & KVM）

```bash
# 查看完整配置
incus config show <实例名>

# 设置开机自启
incus config set <实例名> boot.autostart=true

# 修改 CPU 核数（KVM 需重启生效）
incus config set <实例名> limits.cpu=2

# 修改内存限制（KVM 需重启生效）
incus config set <实例名> limits.memory=2GB

# 修改描述
incus config set <实例名> description "My Web Server"
```

#### 2. LXC 容器专用配置

```bash
# 修改 CPU 调度权重（仅 LXC）
incus config set <实例名> limits.cpu.allowance=40ms/100ms

# 启用嵌套虚拟化（在容器内运行 Docker）
incus config set <实例名> security.nesting=true

# 启用高权限（不仅限于 Docker，慎用）
incus config set <实例名> security.privileged=true
```

#### 3. KVM 虚拟机专用配置

```bash
# 修改磁盘大小（扩容）
# 1. 在宿主机层面扩大虚拟磁盘
incus config device override <虚拟机名> root size=20GB
incus restart <虚拟机名>

# 2. 登录虚拟机扩大分区（Linux 示例）
# incus exec <虚拟机名> -- growpart /dev/sda 3
# incus exec <虚拟机名> -- resize2fs /dev/sda3

# 启用安全启动 (Secure Boot)
incus config set <虚拟机名> security.secureboot=true

# 调整 vCPU 拓扑 (Sockets/Cores/Threads) - 仅限特定场景
# incus config set <虚拟机名> limits.cpu.topology="1:2:2"  # 1 Socket, 2 Cores, 2 Threads
```

#### 4. 端口映射管理

*   **添加端口映射**：
    *   **LXC**:
        ```bash
        incus config device add <实例名> port-80 proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
        ```
    *   **KVM (NAT 模式)**:
        *   需要指定宿主机 IP 和 虚拟机内网 IP。
        ```bash
        incus config device add <实例名> port-80 proxy listen=tcp:宿主机IP:80 connect=tcp:虚拟机内网IP:80 nat=true
        ```

*   **查看端口映射**：
    ```bash
    incus config device show <实例名>
    ```

*   **删除端口映射**：
    ```bash
    incus config device remove <实例名> port-80
    ```

#### 5. 网络带宽限制

*   **设置限速**：
    需要先确定网卡名称（通常是 `eth0`），如果不确定，先运行 `incus config device list <实例名>` 查看。
    ```bash
    # 覆盖 profile 设置并限速
    incus config device override <实例名> eth0 limits.egress=100Mbit limits.ingress=100Mbit
    ```

*   **取消限速**：
    ```bash
    incus config device set <实例名> eth0 limits.egress= limits.ingress=
    ```

### 存储池管理

```bash
# 列出存储池
incus storage list

# 查看存储池详情
incus storage show default

# 查看存储池使用情况
incus storage info default

# 扩容存储池（仅适用于 loop 类型的存储池，如 btrfs/zfs 文件）
incus storage set default size=5GB

# 注意：如果使用的是 incus_manage.sh 创建的独立存储池
# 请将 default 替换为对应的存储池名称，例如：
# incus storage set storage_xxx size=10GB
```

#### 如何缩小存储池（需删除重建）

Incus 的 loop 类型存储池（如 btrfs/zfs 文件）**不支持直接缩小**。如果需要获得更小的存储池，只能**删除并重建**。

**情况一：如果是 `incus_manage.sh` 创建的独立存储池**

这些存储池是跟随实例创建的（名为 `storage_实例名`）。

1.  **删除实例**：使用脚本删除实例，它会自动连带删除对应的独立存储池。
    ```bash
    ./incus_manage.sh delete <实例名>
    ```
2.  **重建实例**：重新运行创建命令，并指定更小的硬盘大小。

**情况二：如果是全局 `default` 存储池**

这是一个更复杂的过程，因为它通常被 `default` Profile 引用，且可能存放了多个容器或镜像。

1.  **备份数据**：将重要数据备份到外部。
2.  **删除依赖资源**：必须删除所有使用该存储池的容器、虚拟机和自定义 Profile。
3.  **解除默认 Profile 关联**：
    ```bash
    # 临时移除 default profile 对存储池的引用
    incus profile device remove default root
    ```
4.  **删除存储池**：
    ```bash
    incus storage delete default
    ```
5.  **重建存储池**（指定新的大小）：
    ```bash
    # 创建 5GB 的 btrfs 存储池
    incus storage create default btrfs size=5GB
    ```
6.  **恢复 Profile 关联**：
    ```bash
    # 将其重新加回 default profile
    incus profile device add default root disk pool=default path=/
    ```

### 镜像管理

```bash
# 列出本地镜像
incus image list

# 搜索可用镜像
incus image list images: debian

# 删除镜像
incus image delete <fingerprint>
```

### 批量操作

```bash
# 停止所有实例
incus list -c n --format csv | xargs -I {} incus stop {}

# 启动所有实例
incus list -c n --format csv | xargs -I {} incus start {}

# 删除所有实例
incus list -c n --format csv | xargs -I {} incus delete -f {}
```

---

## 维护与管理

### 查看实例资源使用

```bash
# 查看所有实例资源使用
incus list -c nscp4ubS

# 解释：n=名称, s=状态, c=CPU时间, p=PID, 4=IPv4, u=上传, b=下载, S=快照数
```

### 清理实例内部空间

```bash
# 进入实例执行（Debian/Ubuntu）
incus exec myserver -- bash -c '
apt-get autoremove -y
apt-get clean
find /var/log -type f -delete
find /var/tmp -type f -delete
find /tmp -type f -delete
find /var/cache/apt/archives -type f -delete
'
```

### 备份与恢复

```bash
# 创建快照
incus snapshot create myserver snapshot1

# 查看快照
incus snapshot list myserver

# 恢复快照
incus snapshot restore myserver snapshot1

# 删除快照
incus snapshot delete myserver snapshot1

# 导出实例为镜像
incus publish myserver --alias my-template

# 从镜像创建新实例
incus init my-template newserver
incus init my-template newvm --vm
```

### 扩展 KVM 虚拟机磁盘

```bash
# 设置新的磁盘大小
incus config device set myvm root size=50GiB

# 进入虚拟机扩展分区
incus exec myvm -- bash

# 在虚拟机内执行
growpart /dev/sda 2
resize2fs /dev/sda2
```

### 删除实例完整流程

**推荐使用脚本删除**（会自动清理存储池）：

```bash
./incus_manage.sh delete myserver
```

**手动删除 LXC**：

```bash
# 1. 停止实例
incus stop myserver

# 2. 删除实例
incus delete myserver

# 3. 删除专用存储池（如果使用独立存储池）
incus storage delete storage_myserver

# 4. 删除信息文件
rm -f myserver.info
```

**手动删除 KVM**：

```bash
# 1. 停止虚拟机
incus stop myvm

# 2. 删除虚拟机
incus delete myvm

# 3. 删除信息文件
rm -f myvm.info
```

---

## 故障排查

### 实例无法启动

1. **检查存储池空间**
   ```bash
   incus storage info default
   ```

2. **检查内存是否超过宿主机可用内存**
   ```bash
   free -h
   incus config get myserver limits.memory
   ```

3. **查看实例日志**
   ```bash
   incus info myserver --show-log
   ```

### KVM 虚拟机无法启动

1. **检查硬件虚拟化支持**
   ```bash
   grep -E '(vmx|svm)' /proc/cpuinfo
   ls -la /dev/kvm
   ```

2. **检查 Secure Boot 设置**
   ```bash
   incus config get myvm security.secureboot
   # 如果镜像不支持 Secure Boot，禁用它
   incus config set myvm security.secureboot=false
   ```

### 磁盘限制不生效（LXC）

1. **确保使用 btrfs 或 zfs 存储池**（dir 格式限制不生效）

2. **启用 btrfs 配额**
   ```bash
   btrfs quota enable /var/lib/incus/storage-pools/default/
   ```

3. **检查限制设置**
   ```bash
   incus config device show myserver root
   ```

### SSH 无法连接

1. **确认端口映射正确**
   ```bash
   incus config device show myserver | grep proxy
   ```

2. **确认实例内 SSH 服务正常**
   ```bash
   incus exec myserver -- systemctl status ssh
   ```

3. **确认防火墙规则**
   ```bash
   # 宿主机防火墙
   iptables -L -n | grep 20001
   ```

### VNC 无法连接（KVM）

```bash
# 检查虚拟机是否运行
incus list

# 尝试使用 incus console
incus console myvm --type=vga
```

### incusd 占用 CPU 过高

参考 [Incusd 高 CPU 问题排查](https://linuxcontainers.org/incus/docs/main/howto/troubleshoot_faq/)：

```bash
# 查看 incusd 状态
systemctl status incusd

# 重启 incusd
systemctl restart incusd
```

---

## 参考资料

- [Incus 官方文档](https://linuxcontainers.org/incus/docs/main/)
- [一键虚拟化项目文档](https://www.spiritlhl.net/guide/incus/incus_lxc.html)
- [Hentioe 的 Incus 使用教程](https://blog.hentioe.dev/posts/incus-usage.html)
- [oneclickvirt/incus GitHub](https://github.com/oneclickvirt/incus)

---

## 更新日志

- 2026-01-21: 重构文档，增加 KVM 虚拟机章节，统一管理脚本 `incus_manage.sh`
- 2026-01-19: 优化文档结构，添加 oneclickvirt 一键脚本使用方法，补充常用命令和故障排查