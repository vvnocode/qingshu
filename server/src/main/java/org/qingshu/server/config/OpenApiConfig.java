package org.qingshu.server.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI 配置类
 * 
 * @author vvnocode
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .openapi("3.0.3")
                .info(new Info()
                        .title("青书API文档")
                        .description("传递爱与情感的平台 - API接口文档")
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("青书团队")
                                .email("contact@qingshu.org"))
                        .license(new License()
                                .name("MIT License")
                                .url("https://opensource.org/licenses/MIT")))
                .servers(List.of(
                        new Server().url("http://localhost:52014").description("开发环境")));
    }
}