# xrayr ipv6 分流解锁 Netflix 脚本

XRAYR_FOLDER="/opt/xrayr"
CONFIG_FOLDER="${XRAYR_FOLDER}/config"
ROUTE_JSON="${CONFIG_FOLDER}/route.json"
OUTBOUND_JSON="${CONFIG_FOLDER}/custom_outbound.json"


add_netflix_rule() {
    # 检查是否有原有的路由规则
    if [ ! -f "${ROUTE_JSON}" ]; then
        echo "route.json 文件不存在，创建文件"
        touch "${ROUTE_JSON}"
        create_route_json
    fi

    # 检查是否有原有的 outbounds 文件
    if [ ! -f "${OUTBOUND_JSON}" ]; then
        echo "custom_outbound.json 文件不存在，创建文件"
        touch "${OUTBOUND_JSON}"
        create_outbound_json
    fi
    
    # 重启
    echo "重启 xrayr"
    docker restart xrayr
}


# 新建路由规则
create_route_json() {
    cat > "${ROUTE_JSON}" <<-EOF
{
    "domainStrategy": "IPOnDemand",
    "rules": [
        {
            "type": "field",
            "outboundTag": "block",
            "ip": [
                "geoip:private"
            ]
        },
        {
            "type": "field",
            "outboundTag": "block",
            "protocol": [
                "bittorrent"
            ]
        },
        {
            "type": "field",
            "outboundTag": "IPv6_out",
            "domain": [
                "geosite:netflix"
            ]
        }
    ]
}
EOF
}

# 新建 outbounds 规则
create_outbound_json() {
    cat > "${OUTBOUND_JSON}" <<-EOF
[
    {
        "tag": "IPv4_out",
        "protocol": "freedom"
    },
    {
        "tag": "IPv6_out",
        "protocol": "freedom",
        "settings": {
            "domainStrategy": "UseIPv6"
        }
    },
    {
        "protocol": "blackhole",
        "tag": "block"
    }
]
EOF
}

add_netflix_rule()
