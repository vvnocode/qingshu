+++
date = '2026-01-09T18:58:00+08:00'
draft = false
title = 'PVE设置指南'
tags = ['PVE', 'Proxmox', '虚拟化', '换源', 'Linux']
+++
## 网络

### 修改IP  

通过webui修改ip，结果服务器起不来，最后**重装PVE**。
**所以修改ip还是去/etc/network/interfaces修改吧。**

重启后的提示语还是显示原来的https://旧IP:8006。这个要是以后忘了就容易出问题。可以更改/etc/hosts文件，也可以在web管理页面主机处修改，修改完记得保存。此操作修改完需要重启才可刷新显示提示语。

---
## 换源

PVE 9.0 基于 Debian 13，除了换 Debian 的软件源以外，还需要编辑企业源、[Ceph 源](https://zhida.zhihu.com/search?content_id=261450863&content_type=Article&match_order=1&q=Ceph+%E6%BA%90&zd_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ6aGlkYV9zZXJ2ZXIiLCJleHAiOjE3NjQ5MjI2NDgsInEiOiJDZXBoIOa6kCIsInpoaWRhX3NvdXJjZSI6ImVudGl0eSIsImNvbnRlbnRfaWQiOjI2MTQ1MDg2MywiY29udGVudF90eXBlIjoiQXJ0aWNsZSIsIm1hdGNoX29yZGVyIjoxLCJ6ZF90b2tlbiI6bnVsbH0.oNEQ5SwQB2LPy_y-TLHT-okgt3MQUh9ru5fRqg3b1hw&zhida_source=entity)、无订阅源以及 CT 模板源。

### **Debian 软件源**

> Debian 13 软件源变更为 `DEB822` 格式 `/etc/apt/sources.list.d/debian.sources` ，不再是传统格式 `/etc/apt/sources.list`

与常规的 Debian 13 一样，将 `/etc/apt/sources.list.d/debian.sources` 中默认源全部删除，将其替换为清华源

```bash
mv /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak && cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
```

### **企业源**

将 PVE 的企业源 `/etc/apt/sources.list.d/pve-enterprise.sources` 注释掉（也可以直接删除）

```bash
mv /etc/apt/sources.list.d/pve-enterprise.sources /etc/apt/sources.list.d/pve-enterprise.sources.bak && sed 's/^/# /' /etc/apt/sources.list.d/pve-enterprise.sources.bak > /etc/apt/sources.list.d/pve-enterprise.sources
```

### **Ceph 源**

将 PVE 的 Ceph 源 `/etc/apt/sources.list.d/ceph.sources` 也替换成清华源

```bash
mv /etc/apt/sources.list.d/ceph.sources /etc/apt/sources.list.d/ceph.sources.bak && cat > /etc/apt/sources.list.d/ceph.sources <<'EOF'
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
```

### **无订阅源**

在 `/etc/apt/sources.list.d` 目录下创建 `pve-no-subscription.sources` 文件，填上以下内容

```bash
cat > /etc/apt/sources.list.d/pve-no-subscription.sources <<'EOF'
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
```

### **CT 模板源**

如果你需要用到 PVE 中的 [LXC 容器](https://zhida.zhihu.com/search?content_id=261450863&content_type=Article&match_order=1&q=LXC+%E5%AE%B9%E5%99%A8&zd_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ6aGlkYV9zZXJ2ZXIiLCJleHAiOjE3NjQ5MjI2NDgsInEiOiJMWEMg5a655ZmoIiwiemhpZGFfc291cmNlIjoiZW50aXR5IiwiY29udGVudF9pZCI6MjYxNDUwODYzLCJjb250ZW50X3R5cGUiOiJBcnRpY2xlIiwibWF0Y2hfb3JkZXIiOjEsInpkX3Rva2VuIjpudWxsfQ.PEurl0CSCO2uVSZbz2iFCwKfzyak6JWBH_FCzEK0hmQ&zhida_source=entity)，那么还需要替换一下 CT 模板源，否则下载模板会非常的慢

将 `/usr/share/perl5/PVE/APLInfo.pm` 文件中默认的源地址 `http://download.proxmox.com` 替换为

```bash
cp /usr/share/perl5/PVE/APLInfo.pm /usr/share/perl5/PVE/APLInfo.pm.bak && sed -i 's|http://download.proxmox.com|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
```

重启后生效

```text
systemctl restart pvedaemon pveproxy
```

### 更新系统

换源后执行：

```bash
apt update && apt full-upgrade -y
```

---
## 删除订阅弹窗

todo

---
## Swap

PVE 官方文档建议：

> “Even large memory machines benefit from a small swap area. VM ballooning and memory reclamation rely on it.”

不少 VM Ballooning、KSM 回收机制依赖 swap 存在。
且VM 的内存是用 “物理内存里” 的，默认不会用到 PVE 的 swap。
所以建议保留Swap。

---
### 添加硬盘

todo

---

## 参考

[PVE 9.0 保姆级安装及优化教程（换源、网络配置、远程唤醒等）【基础篇】](https://zhuanlan.zhihu.com/p/1937263770503186125)
