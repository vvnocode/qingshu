+++
date = '2026-01-09T18:58:00+08:00'
draft = false
title = 'PVE安装指南'
tags = ['PVE', 'Proxmox', '虚拟化', 'Linux']
+++
换源 https://skyao.net/learning-pve/docs/installation/source/#pve9

## 下载镜像

https://www.proxmox.com/en/downloads

![](images/2026/01/6fea97a79e3002f3b06bf8e9bed07dc4.png)

## 内存检查

> Proxmox / Linux 安装阶段对内存稳定性非常敏感。内存配置失误会导致安装时进程卡住。

1. 确保内存条不是奇数条（最好是）
2. 确保BIOS设置的内存条为默认频率（一定要）
	进入 BIOS，把 EXPO 关闭

## 关闭Wait for F1 If Error

防止 BIOS 提示按 F1 继续，增加启动时间。

路径：`Boot → Wait for “F1” If Error → Disabled`

## 断电自启

正常关机不会触发来电自启动，必须意外断电才行

1. 进入 BIOS
2. F7进入Advance mode（高级模式）
3. 高级电源管理（APM）
4. 将Restore AC Power Loss（断电恢复后电源状态）选项设置为Power On（电源开启）
5. F10保存

注意：禁用 USB 上电唤醒（华硕 B650/B850 主板专属问题）  
- **Disabled**（默认，关机后 USB 和一些设备仍带电）  
- **Enabled (S4+S5)**（完全断电）  
- **Enabled (S5)**（半断电）  
Advanced → APM Configuration → ErP Ready -> **Enabled (S4+S5)**（完全断电）

### 允许网络唤醒

1. 1-3参考来电启动
   
2. 由PCI-E设备唤醒设置为开启
   
3. F10保存

## 开启虚拟化

>**Intel（VMX）Virtualization Technology**（英特尔虚拟化技术）是英特尔公司开发的一种硬件辅助虚拟化技术，旨在提高系统的可管理性、安全性和灵活性。它允许在一台物理计算机上同时运行多个操作系统和应用程序，每个操作系统运行在一个独立的虚拟机（VM）中，从而实现资源的高效利用和隔离。  
> 其技术组成包括：  
>**1、处理器虚拟化技术（Intel VT-x）**：使虚拟机监视器（VMM）能够在Intel x86 CPU上直接运行，无需通过二进制翻译技术来模拟。  
>**2、内存虚拟化技术（EPT）**：通过扩展页表技术，提高内存虚拟化的性能和效率。  
>**3、I/O虚拟化技术（Intel VT-d）**：为虚拟化环境中的I/O设备提供硬件加速，使虚拟机能够直接访问物理I/O设备，同时保证性能和安全。  
>**4、网络虚拟化技术（Intel VT-c）**：支持多队列、多核心和多路复用等功能，提高虚拟机的网络吞吐量和响应速度。

### 华硕主板操作步骤

>[如何通过 BIOS 设置启用和安装虚拟机](https://www.asus.com.cn/support/faq/1045141/)

#### Intel

1. 电脑开机后，立刻按压键盘上的’delete’键，进入BIOS [EZ Mode]页面
2. 按压键盘F7键，进入Advance Mode
3. 点选 [Advanced]页面并点选[CPU Configuration]选项
4. 点选[Intel(VMX) Virtualization Technology]选项并设置为[Enabled]
5. 按压键盘F10键，点击[Ok]，保存选项，待电脑重启后，即完成BIOS设置

#### AMD

1. 电脑开机后，立刻按压键盘上的’delete’键，进入BIOS [Advanced Mode]页面
2. 点选 [Advanced]页面并点选[CPU Configuration]选项
3. 点选[SVM Mode]选项并设置为[Enabled]
4. 按压键盘F10键，点击Ok，保存选项，待电脑重启后，即完成BIOS设置

## 写入镜像

1. 下载写盘工具
	https://etcher.balena.io/#download-etcher
	选择 Etcher for macOS (arm64)
2. 选择镜像和U盘后烧录
	![](images/2026/01/6753211cd73dd98e1126fa8181e4a8a1.png)

## 安装PVE

### 1. 插上U盘，重启电脑（BIOS页面ctrl + alt + delete重启）

### 2. 选择第一个

![](images/2026/01/e5acd1f7f7cc451c94ebdf2d17d9e721.png)

### 3. 进入下面页面安装正式开始，首先使用协议页面点击 I agree（我同意）。

### 4. 选择pve安装的硬盘，然后继续点击Next(下一步）。

![](images/2026/01/74979ee1a41e4fc540d2581b59631153.png)

### 5. 设置国家、时区、键盘布局，然后点击Next(下一步）

![](images/2026/01/160e875a74c084508909b10073ebd977.png)

### 6. 设置密码、和邮箱，继续点击Next(下一步）

![](images/2026/01/a6d0c81f6758edd2e0b7be8b5d704119.png)

### 7. 设置网卡、域（保持默认即可）、PVE管理地址、网关、DNS等，继续点击Next(下一步）

我的局域网网段是10.100.2.XXX，按照以下设置，**可根据自己的局域网端进行自定义**

> **Management Interface（管理接口）**：选 `enp1s0`，后面跟着一串字符 `XX:XX:XX:XX:XXX:X (igc)`，这表示网络接口的名称和MAC地址，以及使用的驱动程序（igc）。这个接口用于管理网络连接。  
> **Hostname (FQDN)（主机名，完全限定域名）**：这里设置的是 `pve.example.com`，这是系统的主机名，通常也是完全限定域名（FQDN），用于网络中的标识。  
> **IP Address (CIDR)（IP地址，无类别域间路由）**：这里设置的是 `10.100.2.231/24`，表示分配给该主机的IP地址是10.100.2.231，CIDR表示子网掩码长度，/24表示子网掩码是255.255.255.0，这意味着该网络可以有256个IP地址（从10.100.2.0到10.100.2.255）。
> **Gateway（网关）**：这里设置的是 `10.100.2.1`，这是网络的默认网关地址，通常是路由器的IP地址，用于转发数据包到其他网络。  
> **DNS Server（域名系统服务器）**：这里设置的是默认的运营商地址。

![](images/2026/01/05abf997b21ed9677dd68ff9af560160.png)

### 8. 在配置详情中检查配置信息是否有误，没有问题点击Install（安装）

![](images/2026/01/9d664c6e5a5244af8206adf2f9645995.png)

### 9. 安装完成后移除U盘，然后点击Reboot重启机器

![](images/2026/01/fc45f2d89ff232819ffea918d41fac22.png)

## 恢复内存

1. 将拔出的内存插回去
2. 进入BIOS，设置EXPO

## 初始化

当出现login终端代表启动完毕，可以通过浏览器访问了。

### 1. 在浏览器输入 https://10.100.2.xxx:8006 进入PVE后台

用户名为root，密码为在安装时设置的密码
![](images/2026/01/12bcdbec464b9b3bfcbb67367360ba02.png)

### 2. 登录后PVE会提示“没有有效订阅”，点击确定忽略，这个订阅是针对专业/企业级用户的，普通用户无需理会。

![](images/2026/01/4c444d69412765d9f8967bbeb909b22f.png)

### 3. 检查网络是否可用

确认网络是否连通