# 多阶段构建 - 第一阶段：构建自定义JRE
FROM eclipse-temurin:21-jdk-alpine AS jre-builder

# 安装构建工具
RUN apk update && apk add binutils

# 使用jlink创建最小化JRE
RUN $JAVA_HOME/bin/jlink \
    --verbose \
    --add-modules java.base,java.logging,java.net.http,java.sql,java.management \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=2 \
    --output /optimized-jdk-21

# 第二阶段：运行环境
FROM alpine:latest

ENV JAVA_HOME=/opt/jdk/jdk-21
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# 复制优化后的JRE
COPY --from=jre-builder /optimized-jdk-21 $JAVA_HOME

# 创建非root用户
RUN addgroup --system spring && adduser --system spring --ingroup spring

# 设置应用目录
RUN mkdir /app && chown -R spring /app
WORKDIR /app
USER spring

# 复制应用
COPY --chown=spring:spring target/*.jar app.jar

# JVM优化参数
ENV JAVA_OPTS="-Xmx256m -Xms128m -XX:+UseG1GC -XX:+UseStringDeduplication"

EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]