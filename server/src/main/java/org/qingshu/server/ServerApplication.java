package org.qingshu.server;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("org.qingshu.server.dal.mysql")
public class ServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(ServerApplication.class, args);
        System.out.println("""
                
                ========================================
                🌸 青书 - 传递爱与情感的平台 🌸
                ========================================
                
                🚀 应用启动成功！
                
                📖 API文档: http://localhost:52014/swagger-ui.html
                📝 接口地址: http://localhost:52014/v3/api-docs
                🌐 服务地址: http://localhost:52014
                
                ========================================
                """);
    }

}
