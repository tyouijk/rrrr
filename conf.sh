#!/bin/bash
web="ubuntu.com"
UUID="cb78c1d7-177c-4cf7-9df8-991179d709fa"
if [[ ! -d web ]]; then
    wget -O v.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
    mkdir web
    unzip -qo v.zip -d web/
    chmod +x web/xray
    mv web/xray web/x
    rm -f v.zip
fi
if [[ ! -f c ]]; then
    wget -O c "https://caddyserver.com/api/download?os=linux&arch=amd64&idempotency=98167146327429"
    chmod +x c
fi
cat > Caddyfile <<-EOF
:8080
reverse_proxy https://$web {
    header_up Host {upstream_hostport}
    header_up X-Forwarded-Host {host}
}

@websocket_vmess {
    path /$UUID-vmess
}
reverse_proxy @websocket_vmess 127.0.0.1:8081

@websocket_vless {
    path /$UUID-vless
}
reverse_proxy @websocket_vless 127.0.0.1:8082

@websocket_trojan {
    path /$UUID-trojan
}
reverse_proxy @websocket_trojan 127.0.0.1:8083
EOF
cat > web/config.json <<-EOF
{
    "inbounds": 
    [
        {
            "port": 8081,"protocol": "vmess",
            "settings": {"clients": [{"id": "$UUID"}]},
            "streamSettings": {"network": "ws","wsSettings": {"path": "/$UUID-vmess"}}
        },
        {
            "port": 8082,"protocol": "vless",
            "settings": {"clients": [{"id": "$UUID"}],"decryption": "none"},
            "streamSettings": {"network": "ws","wsSettings": {"path": "/$UUID-vless"}}
        },
        {
            "port": 8083,"protocol": "trojan",
            "settings": {"clients": [{"password": "$UUID"}]},
            "streamSettings": {"network": "ws","wsSettings": {"path": "/$UUID-trojan"}}
        }
    ],
    
    "outbounds": 
    [
        {"protocol": "freedom","tag": "direct","settings": {}},
        {"protocol": "blackhole","tag": "blocked","settings": {}},
        {"protocol": "freedom","tag": "twotag","streamSettings": {"network": "domainsocket","dsSettings": {"path": "apath","abstract": true}}}
    ],
    
    "routing": 
    {
        "rules": 
        [
            {"type": "field","inboundTag": ["onetag"],"outboundTag": "twotag"},
            {"type": "field","outboundTag": "blocked","domain": ["geosite:category-ads-all"]}
        ]
    }
}
EOF
