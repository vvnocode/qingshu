# 情书项目

## 项目简介
这是一个基于Spring Boot的后端服务项目。

## 开发环境要求
- JDK 21
- Maven 3.8+
- Docker (可选，用于容器化部署)

## 本地开发启动

### 1. 克隆项目
```bash
git clone [项目地址]
cd qingshu
```

### 2. 编译项目
```bash
cd server
mvn clean package
```

### 3. 运行项目
```bash
java -jar target/server.jar
```

## Docker部署

### 1. 手动构建Docker镜像
确保您已经完成了项目的编译（生成了jar文件），然后在server目录下执行：

```bash
# 构建镜像
docker build -t vvnocode/qingshu-server:latest .

# 发布镜像
docker push vvnocode/qingshu-server:latest

# 运行容器
docker run -d -p 52014:52014 --name qingshu-server vvnocode/qingshu-server:latest
```

### 2. 自定义JVM参数
如果需要自定义JVM参数，可以在运行容器时通过环境变量设置：

```bash
docker run -d -p 8080:8080 \
  -e "JAVA_OPTS=-Xms512m -Xmx512m" \
  --name qingshu-server \
  qingshu-server:latest
```

### 3. 查看容器状态
```bash
# 查看容器运行状态
docker ps

# 查看容器资源使用情况
docker stats qingshu-server

# 查看容器日志
docker logs qingshu-server
```

## 项目配置说明

### 环境变量
- `JAVA_OPTS`: JVM参数配置，默认为 `-Xms256m -Xmx256m`
- `TZ`: 时区设置，默认为 `Asia/Shanghai`

### 端口说明
- 8080: 应用服务端口

## 常见问题

### 1. 内存使用过高
如果发现容器内存使用过高，可以：
1. 调整JVM参数限制内存使用
2. 使用 `docker stats` 命令监控内存使用情况
3. 检查应用是否存在内存泄漏

### 2. 容器无法启动
1. 检查端口是否被占用
2. 查看容器日志：`docker logs qingshu-server`
3. 确保jar文件已正确构建

## 贡献指南
1. Fork 项目
2. 创建特性分支
3. 提交代码
4. 创建 Pull Request

## 许可证
MIT