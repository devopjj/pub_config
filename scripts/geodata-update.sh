#!/bin/bash

MOSDNS_PATH=$(dirname "$0")
PARENT_PATH=$(dirname "$MOSDNS_PATH")

[[ ! -d "$MOSDNS_PATH/downloads/" ]] && mkdir -p "$MOSDNS_PATH/downloads/"

echo "Downloading geoip.zip..."
curl --progress-bar -JL -o $MOSDNS_PATH/downloads/geoip.zip https://github.com/techprober/v2ray-rules-dat/raw/release/geoip.zip
echo "Downloading geosite.zip..."
curl --progress-bar -JL -o $MOSDNS_PATH/downloads/geosite.zip https://github.com/techprober/v2ray-rules-dat/raw/release/geosite.zip
echo "Extracting geoip.zip to ips/ ..."
unzip -qq -o $MOSDNS_PATH/downloads/geoip.zip -d $PARENT_PATH/ips
echo "Extracting geosite.zip to domains/ ..."
unzip -qq -o $MOSDNS_PATH/downloads/geosite.zip -d $PARENT_PATH/domains

echo "Finished."