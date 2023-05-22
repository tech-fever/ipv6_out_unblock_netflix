# xrayr ipv6 分流解锁 Netflix 脚本

XRAYR_FOLDER="/opt/xrayr"
CONFIG_FOLDER="${XRAYR_FOLDER}/XrayR"
CONFIG_YAML="${CONFIG_FOLDER}/config.yml"
ROUTE_JSON="${CONFIG_FOLDER}/route.json"
OUTBOUND_JSON="${CONFIG_FOLDER}/custom_outbound.json"

# GEOIP_DAT="https://github.com/v2fly/geoip/releases/latest/download/geoip.dat"
GEOIP_DAT="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_DAT="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"

download_dat() {
    # 下载 geoip.dat
    echo "下载 geoip.dat"
    wget -O "${CONFIG_FOLDER}/geoip.dat" "${GEOIP_DAT}"
    # 下载 geosite.dat
    echo "下载 geosite.dat"
    wget -O "${CONFIG_FOLDER}/geosite.dat" "${GEOSITE_DAT}"

    # 检查 geoip.dat 是否下载成功
    if [ ! -f "${CONFIG_FOLDER}/geoip.dat" ]; then
        echo "geoip.dat 下载失败，请检查网络"
        exit 1
    fi
    # 检查 geosite.dat 是否下载成功
    if [ ! -f "${CONFIG_FOLDER}/geosite.dat" ]; then
        echo "geosite.dat 下载失败，请检查网络"
        exit 1
    fi
    # 下载成功
    echo "下载成功"
}

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
    download_dat
    change_config_yaml
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


change_config_yaml() {
    # RouteConfigPath: # /etc/XrayR/route.json
    # 替换成
    # RouteConfigPath: /etc/XrayR/route.json
    sed -i 's/RouteConfigPath: # \/etc\/XrayR\/route.json/RouteConfigPath: \/etc\/XrayR\/route.json/g' "${CONFIG_YAML}"
    # OutboundConfigPath: # /etc/XrayR/custom_outbound.json
    # 替换成
    # OutboundConfigPath: /etc/XrayR/custom_outbound.json
    sed -i 's/OutboundConfigPath: # \/etc\/XrayR\/custom_outbound.json/OutboundConfigPath: \/etc\/XrayR\/custom_outbound.json/g' "${CONFIG_YAML}"
    # 打印结果
    echo "修改后的 config.yml 文件内容如下："
    # 打印 RouteConfigPath
    echo "RouteConfigPath: $(grep "RouteConfigPath" "${CONFIG_YAML}")"
    # 打印 OutboundConfigPath
    echo "OutboundConfigPath: $(grep "OutboundConfigPath" "${CONFIG_YAML}")"
}
# 运行函数
add_netflix_rule
