# 青书 - 传递爱与情感的平台

🌸 一个专注于情感表达和爱意传递的在线平台，让每一份真挚的情感都能找到最美的表达方式。

## 📖 项目概述

青书是一个情感交流平台，主要功能包括：

- **情书创作** - 基于精美模板快速创作个性化情书
- **模板中心** - 提供丰富的情书模板，涵盖浪漫告白、生日祝福、纪念日等多种场景
- **社区交流** - 用户可以分享情感故事，互动交流
- **发现功能** - 探索热门内容和精选推荐

## 🛠️ 技术架构

### 后端技术栈
- **框架**: Spring Boot 3.5.0
- **数据访问**: MyBatis Plus 3.5.9
- **数据库**: MariaDB 10.11
- **工具库**: Lombok、Hutool
- **文档**: Swagger (OpenAPI 3)
- **构建工具**: Maven

### 项目结构
```
server/
├── src/main/java/org/qingshu/server/
│   ├── controller/          # 控制器层
│   ├── service/            # 业务逻辑层
│   │   └── impl/          # 业务实现
│   ├── dal/               # 数据访问层
│   │   ├── dataobject/    # 数据对象
│   │   └── mysql/         # Mapper接口
│   └── framework/         # 框架基础代码
│       ├── common/        # 通用组件
│       ├── mybatis/       # MyBatis配置
│       └── web/           # Web配置
├── src/main/resources/    # 配置文件
└── sql/                   # 数据库脚本
```

## 🚀 快速开始

### 环境要求
- Java 21+
- Maven 3.6+
- MariaDB 10.11+

### 1. 克隆项目
```bash
git clone <repository-url>
cd qingshu
```

### 2. 数据库配置
1. 创建数据库：
```sql
CREATE DATABASE qingshu CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

2. 执行数据库脚本：
```bash
mysql -u root -p qingshu < server/sql/qingshu.sql
```

3. 修改数据库连接配置（`server/src/main/resources/application.yaml`）：
```yaml
spring:
  datasource:
    url: jdbc:mariadb://localhost:3306/qingshu?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai
    username: your_username
    password: your_password
```

### 3. 编译和运行
```bash
cd server
mvn clean install
mvn spring-boot:run
```

### 4. 访问应用
- **API文档**: http://localhost:52014/swagger-ui.html
- **接口地址**: http://localhost:52014/v3/api-docs
- **服务地址**: http://localhost:52014


## Docker部署

### 1. 手动构建Docker镜像
确保您已经完成了项目的编译（生成了jar文件），然后在server目录下执行：

```bash
# 构建镜像
docker build -t vvnocode/qingshu-server:latest .

# 发布镜像
docker push vvnocode/qingshu-server:latest

# 运行容器
docker pull vvnocode/qingshu-server:latest
docker-compose up -d
```

## 📚 API文档

项目集成了Swagger，启动后可以通过以下地址查看完整的API文档：
- Swagger UI: http://localhost:52014/swagger-ui.html

### 主要API模块
- **用户管理** (`/api/users`) - 用户CRUD操作
- **情书模板** (`/api/templates`) - 模板管理和查询

## 🗄️ 数据库设计

### 核心数据表
- `qs_user` - 用户表
- `qs_template` - 情书模板表
- `qs_template_category` - 模板分类表
- `qs_user_creation` - 用户创作表
- `qs_community_post` - 社区帖子表
- `qs_comment` - 评论表
- `qs_like` - 点赞表
- `qs_user_follow` - 用户关注表

## 🎯 开发指南

### 代码规范
- 遵循芋道源码项目的代码风格
- 使用统一的命名规范和注释标准
- 实体类统一继承`BaseDO`基类
- 使用`CommonResult`统一响应格式

### 新增功能开发
1. 在`dal/dataobject`中定义数据对象
2. 在`dal/mysql`中创建Mapper接口
3. 在`service`中定义业务接口
4. 在`service/impl`中实现业务逻辑
5. 在`controller`中创建REST API

## 🔧 配置说明

### 应用配置
- 端口: 52014
- 数据库: MariaDB
- 日志级别: DEBUG (开发环境)

### MyBatis Plus配置
- 自动填充创建时间、更新时间等字段
- 逻辑删除支持
- 下划线转驼峰命名

## 📝 更新日志

### v1.0.0 (2024-01-xx)
- ✨ 初始版本发布
- 🎉 用户管理功能
- 🎨 情书模板系统
- 📖 API文档集成
- 🏗️ 基础架构搭建

## 📄 许可证

本项目采用 [MIT License](LICENSE) 许可证。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来改进项目！

---

<div align="center">
💝 用代码传递爱，让情感有温度 💝
</div>