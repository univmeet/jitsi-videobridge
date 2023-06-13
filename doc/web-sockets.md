# 网络套接字（WebSocket）

## 简介

WebSocket可以替代WebRTC数据通道（Data Channel），用于传输Colibri客户端到桥接器的信息。这需要桥接器和客户端的支持。

启用WebSocket时，桥接器会公布Colibri WebSocket的URL及其ICE候选。这个URL特定于某个端点（实际上，ICE用户名片段会被重用并编码为URL参数，用于认证），连接这个URL时会路由到桥接器中对应的端点（Endpoint）。

URL格式如下：

```
wss://example.com/colibri-ws/server-id/conf-id/endpoint-id?pwd=123
```

加密OCTO中继的URL格式如下：

```
wss://example.com/colibri-relay-ws/server-id/conf-id/relay-id?pwd=123
```

## 配置桥接器

要启用桥接器上的WebSocket，需要启用可公开访问的HTTP服务器和WebSocket。

1. 在`jvb.conf`中配置可公开访问的HTTP服务器：

+ 启用不使用TLS的可公开访问的HTTP服务器：

```
videobridge {
    http-servers {
        public {
            port = 9090
        }
    }
}
```

+ 启用使用TLS的可公开访问的HTTP服务器：

```
videobridge {
    http-servers {
        public {
            tls-port = 443
            key-store-path=/etc/jitsi/videobridge/ssl.store
            key-store-password=KEY_STORE_PASSWORD
        }
    }
}
```

2. 启用WebSocket：

```
videobridge {
    websockets {
        enabled = true
        # 或false，取决于HTTP服务器配置
        tls = true
        # 这个端口是为WebSocket公布的端口，即客户端使用的可公开访问的端口。
        # 这个端口可能与HTTP服务器公开的端口相同，但是使用代理时也可能不同。
        domain = "example.com:443"
        # 可选的服务器ID。
        # HTTP代理面对一组jitsi-videobridge实例，并且这些实例公布了相同域名时，这个服务器ID很有用。
        server-id = jvb2
    }
}
```

## 配置代理

使用HTTP代理时，需要支持WebSocket。以下是面对两个桥接器的`nginx`配置示例。这两个桥接器分别使用了不使用TLS的`9090`和`9091`端口，并分别配置为`COLIBRI_WS_SERVER_ID=jvb1`和`jvb2`（如上所述）。

```
   # jvb1的Colibri（JVB）Websocket
   location ~ ^/colibri-ws/jvb1/(.*) {
       proxy_pass http://127.0.0.1:9090/colibri-ws/jvb1/$1$is_args$args;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       tcp_nodelay on;
   }
   # jvb2的Colibri（JVB）Websocket
   location ~ ^/colibri-ws/jvb2/(.*) {
       proxy_pass http://127.0.0.1:9091/colibri-ws/jvb2/$1$is_args$args;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_set_header Host alpha.jitsi.net;
       tcp_nodelay on;
   }
```

这个配置允许两个jitsi-videobridge实例运行在同一台机器上，这在测试OCTO时很有用。

加密OCTO需要代理`/colibri-relay-ws`端点：

```
   # jvb1的Colibri加密OCTO中继Websocket
   location ~ ^/colibri-relay-ws/jvb1/(.*) {
       proxy_pass http://127.0.0.1:9090/colibri-relay-ws/jvb1/$1$is_args$args;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       tcp_nodelay on;
   }
   # jvb2的Colibri加密OCTO中继Websocket
   location ~ ^/colibri-relay-ws/jvb2/(.*) {
       proxy_pass http://127.0.0.1:9091/colibri-relay-ws/jvb2/$1$is_args$args;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_set_header Host alpha.jitsi.net;
       tcp_nodelay on;
   }
```

## 排查问题

要验证WebSocket是否已经配置并且可以使用，首先，需要检查是否已向客户端公布Colibri WebSocket URL。然后，打开一个会议，并在JavaScript控制台日志中查找`session-initiate`。展开XML并查找`description -> content -> transport`。应该可以看到一个`web-socket`元素（可以在`meet.jit.si`上验证），如下所示：

```xml
<web-socket xmlns="http://jitsi.org/protocol/colibri" url="wss://meet-jit-si-eu-west-2b-s5-jvb-51.jitsi.net:443/colibri-ws/default-id/4f9cb343985d4779/c814b6a6?pwd=23btmrjol5i83thk1t9s78bnkk"/>
```

要确保URL是正确的，并且基础设施会把这个URL路由到正确的jitsi-videobridge实例。最后，检查Chrome开发控制台的`Network`选项卡，并查找这个URL的请求。应该可以看到为这个URL打开的WebSocket，并且每隔几秒就会交换一次信息。
