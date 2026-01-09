+++
date = '2026-01-09T18:58:00+08:00'
draft = false
title = 'PVE迁移虚拟机'
tags = ['PVE', 'Proxmox', '虚拟化', '迁移', '备份']
+++
记录从PVE intel 上迁移vm到PVE AMD上。
**注意AMD一定要进入 BIOS，把 EXPO 关闭。否则连网络传输大文件都有可能出错。**

## 1. 更改VM处理器类型

改为兼容性更高的x86-64-v2。
kvm64比较老，不推荐。
![](images/2026/01/225d10e3da7c8711eead0128e6df75e0.png)

## 2. 备份VM

![](images/2026/01/b9164ab9e24b6909d70e4868122c54b5.png)
备份文件为 `vzdump-qemu-102-2025_12_05-11_50_02.vma.zst`
![](images/2026/01/ef06ebfb4c5f0efb2ec04a2d66df5095.png)

## 3. 传输备份文件

将备份文件夹传输到另一台PVE
```bash
rsync -avP /var/lib/vz/dump/vzdump-qemu-102-2025_12_05-11_50_02.vma.zst root@10.100.4.100:/var/lib/vz/dump/
```

## 4. 校验文件

分别在原PVE和目标PVE执行，检查两边是否一致。如果不一致考虑是开启了EXPO等超频技术或者其他兼容性问题。

```bash
sha256sum /var/lib/vz/dump/vzdump-qemu-102-2025_12_05-11_50_02.vma.zst
```

## 5. 恢复VM

### 方式一：

在webui操作
![](images/2026/01/617cfac98d18bf858177b33b68176409.png)

在webui恢复可能会提示vm-102-cloudinit已经存在：
`lvcreate 'pve/vm-104-cloudinit' error: Logical Volume "vm-104-cloudinit" already exists in volume group "pve"`

处理办法：
1. 移除对应的已存在的cloudinit
	![](images/2026/01/5532cf4c8572d94fd249adb84264eeb4.png)
2. 可以尝试使用命令行恢复。
### 方式二：

执行脚本
```bash
qmrestore /var/lib/vz/dump/vzdump-qemu-102-2025_12_05-11_50_02.vma.zst 102 \
  --storage local-lvm --unique 1
```

说明：
- 102：指定VMID
- --storage local-lvm：明确指定放到现在的 LVM-Thin（data）上，视情况更改
- --unique 1：如果备份里有 cloud-init/disk 的旧 volume ID，会强制用新的 volume 名，避免名字冲突。

## 6. 配置新IP

配置新的IP和网关
![](images/2026/01/11d72fd58ffcb56927398cc9ce750038.png)