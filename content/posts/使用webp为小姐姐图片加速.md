+++
date = '2024-08-07T19:57:04+08:00'
draft = false
title = '使用webp为小姐姐图片加速'
tags = ['WebP', 'Nginx', '图片优化', '性能优化']
+++
### 技术说明

#### webp

#### nginx

#### webp_server_go

- [webp-sh/webp_server_go](https://github.com/webp-sh/webp_server_go)

### 实现

#### 解压

```shell
find Coser.xgmoe.collection.pack -name "*.zip" -exec sh -c 'unzip -d "/mnt/user/Pictures/Collection/Coser/Coser.xgmoe.collection.pack/" "$0"' {} \;
```

#### zfile4

#### webp_server_go

#### Nginx

```nginx
server {
    # 监听端口 3041，启用SSL加密
    listen 18783 ssl; 
    # 绑定域名
    server_name a.b;  
    
    # 当请求非SSL时，自动重定向到SSL协议
    error_page 497 https://$host:$server_port$request_uri;

    # SSL证书、私钥文件路径
    ssl_certificate      /etc/nginx/ssl/a.b_bundle.crt;
    ssl_certificate_key  /etc/nginx/ssl/a.b.key;
    
    # 允许上传文件大小
    client_max_body_size 200M;
    
    # 所有请求反向代理
    location / { 
        proxy_pass http://127.0.0.1:8783;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location ~* ^/pd/(.*\.(jpg|png))$ {
        proxy_pass http://127.0.0.1:3333/$1;
    }

}
```


![image-20231216212027385](static/images/ac09b3a92245f4a70ae509564a7ea3ef_MD5.jpg)



webp-server -prefetch -jobs=12 --config=/etc/config.json

> 有问题

![image-20231217155151654](static/images/356ed5334ef3a30d6aa61f4b03d5c315_MD5.jpg)

### 参考

- [nginx 之 proxy_pass详解](https://www.jianshu.com/p/b010c9302cd0)
- [正则表达式全部符号解释](https://www.cnblogs.com/yirlin/archive/2006/04/12/373222.html)
- [nginx 正则匹配配置](https://www.cnblogs.com/xiao-xue-di/p/15079370.html)
- [Nginx正则配置](https://juejin.cn/post/6844903992871370766)
- [使用WebP Server Go来加速站点本地图片访问速度](https://shangjixin.com/archives/webp-server-go.html)
- [使用WebP-Server-Go无缝转换图片为Google的webp格式让你网站访问加载速度飞起来](https://cloud.tencent.com/developer/article/2129906)