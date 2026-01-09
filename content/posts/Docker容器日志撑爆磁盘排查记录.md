+++
date = '2026-01-09T11:38:00+08:00'
draft = false
title = 'Docker容器日志撑爆磁盘排查记录'
tags = ['Docker', 'Linux', '运维', '故障排查']
+++

## 问题背景

生产环境虚拟机磁盘告警，使用率达到 94%，需要排查占用空间的文件并进行清理。

<!-- 截图：df -h 输出，显示磁盘使用 94% -->
![](static/images/ead21a313e230d22001b2787f4069e22_MD5.jpg)

## 环境信息

- 操作系统：Ubuntu（虚拟机）
- 磁盘容量：1.8T，已使用 1.6T
- 主要服务：GitLab、MySQL、Redis、Nexus3、SkyWalking 等（均运行在 Docker 中）

<!-- 截图：docker ps 显示运行中的容器 -->
![](static/images/c5cd3ec63e1ced79720dfd39a39d84df_MD5.jpg)

## 排查过程

### 第一步：定位大文件目录

首先使用 `docker system df -v` 查看 Docker 各组件的磁盘占用：

```bash
docker system df -v
```

发现 Images 和 Volumes 占用正常，但 Containers 数据异常。

进一步检查 Docker 数据目录：

```bash
du -sh /var/lib/docker/*
```

输出结果：

```
88K     /var/lib/docker/buildkit
556G    /var/lib/docker/containers
37M     /var/lib/docker/image
188K    /var/lib/docker/network
```

🔴 **发现问题**：`/var/lib/docker/containers` 目录占用了 **556GB**！

### 第二步：定位具体容器

查看每个容器的日志文件大小：

```bash
for id in $(ls /var/lib/docker/containers/); do
  name=$(docker inspect --format '{{.Name}}' $id 2>/dev/null | tr -d '/')
  log_file="/var/lib/docker/containers/$id/$id-json.log"
  if [ -f "$log_file" ]; then
    size=$(ls -lh "$log_file" | awk '{print $5}')
    echo "$size - $name ($id)"
  fi
done | sort -rh
```

输出结果：

```
317G - gitlab (5b4956fd2844...)
126G - yudao-gateway (ea4aced17d6f...)
113G - skywalking-oap (e52e24904a50...)
96M - nexus3 (0ae360065015...)
...
```

🎯 **找到元凶**：三个容器的日志文件吃掉了 556GB 磁盘空间！

| 容器 | 日志大小 | 占比 |
|------|---------|------|
| gitlab | 317GB | 57% |
| yudao-gateway | 126GB | 23% |
| skywalking-oap | 113GB | 20% |

## 问题原因

Docker 容器默认使用 `json-file` 日志驱动，**不限制日志文件大小**。当容器长期运行且输出大量日志时，日志文件会无限增长，最终撑爆磁盘。

这三个服务的特点：
- **GitLab**：CI/CD 流水线日志、Git 操作日志量大
- **yudao-gateway**：API 网关，所有请求都有日志
- **SkyWalking OAP**：链路追踪，数据量大

## 解决方案

### 1. 立即清理日志（不停止容器）

使用 `truncate` 命令清空日志文件：

```bash
# 清空 GitLab 日志
truncate -s 0 /var/lib/docker/containers/5b4956fd28442d57b8c4698d5a26081f01b9f31ec4febace3fc3e29ad89eea4a/5b4956fd28442d57b8c4698d5a26081f01b9f31ec4febace3fc3e29ad89eea4a-json.log

# 清空 yudao-gateway 日志
truncate -s 0 /var/lib/docker/containers/ea4aced17d6f4ebe562440c8f94ff69e0e515efd3c6394787a4419ffc6b866fc/ea4aced17d6f4ebe562440c8f94ff69e0e515efd3c6394787a4419ffc6b866fc-json.log

# 清空 skywalking-oap 日志
truncate -s 0 /var/lib/docker/containers/e52e24904a504b0b5ec67a065d8805f33639dd519b3a2909ed5d9e6d72c0ba66/e52e24904a504b0b5ec67a065d8805f33639dd519b3a2909ed5d9e6d72c0ba66-json.log
```

> ⚠️ **注意**：不要使用 `rm` 删除日志文件，因为容器进程仍然持有文件句柄，删除后空间不会释放。使用 `truncate` 可以在不中断服务的情况下清空日志。

### 2. 配置 Docker 日志轮转（永久解决）

编辑 Docker 守护进程配置文件 `/etc/docker/daemon.json`并增加下面两个参数：

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
```

配置说明：
- `max-size`: 单个日志文件最大 100MB
- `max-file`: 最多保留 3 个日志文件

重启 Docker 使配置生效：

```bash
systemctl restart docker
```

> ⚠️ **注意**：重启 Docker 会导致所有容器重启。此配置仅对新创建的容器生效，已有容器需要重建。

### 3. 单个容器配置日志限制

如果不想全局配置，可以在运行容器时单独指定：

```bash
docker run -d \
  --log-opt max-size=100m \
  --log-opt max-file=3 \
  your-image
```

或在 `docker-compose.yml` 中配置：

```yaml
services:
  your-service:
    image: your-image
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

## 知识点补充

### Docker 日志 vs 应用日志

Docker 容器有两套日志：

| 类型 | 路径 | 说明 |
|------|------|------|
| Docker 容器日志 | `/var/lib/docker/containers/<id>/<id>-json.log` | 容器 stdout/stderr 输出 |
| 应用内部日志 | 挂载的 volume 目录（如 `/srv/gitlab/logs`） | 应用自己的日志文件 |

两者需要分别管理，本次问题出在 Docker 容器日志。

### 常用排查命令

```bash
# 查看 Docker 磁盘使用概览
docker system df

# 详细查看每个组件的磁盘使用
docker system df -v

# 查看指定容器的日志文件大小
ls -lh $(docker inspect --format='{{.LogPath}}' <container_name>)

# 实时查看容器日志（最后100行）
docker logs --tail 100 -f <container_name>

# 清理未使用的 Docker 资源（镜像、容器、网络、构建缓存）
docker system prune -a
```

## 总结

1. Docker 默认不限制容器日志大小，生产环境必须配置日志轮转
2. 使用 `truncate` 可以在不停止容器的情况下清空日志
3. 建议全局配置 `/etc/docker/daemon.json` 限制日志大小
4. 定期检查磁盘使用情况，可设置监控告警

## 参考

- [Docker Logging Documentation](https://docs.docker.com/config/containers/logging/configure/)
- [Configure logging drivers](https://docs.docker.com/config/containers/logging/json-file/)
