#!/bin/bash

# 生成自签名 SSL 证书脚本（仅用于开发/测试环境）
# 生产环境请使用 Let's Encrypt 证书

set -e

# 配置变量
DOMAIN="${1:-localhost}"
CERT_DIR="/etc/nginx/ssl/${DOMAIN}"
DAYS=365

echo "生成自签名 SSL 证书..."
echo "域名: ${DOMAIN}"
echo "证书目录: ${CERT_DIR}"
echo "有效期: ${DAYS} 天"
echo ""

# 创建证书目录
sudo mkdir -p "${CERT_DIR}"

# 生成私钥和证书
sudo openssl req -x509 -nodes -days ${DAYS} \
    -newkey rsa:2048 \
    -keyout "${CERT_DIR}/privkey.pem" \
    -out "${CERT_DIR}/fullchain.pem" \
    -subj "/C=CN/ST=State/L=City/O=Organization/OU=Department/CN=${DOMAIN}"

# 设置权限
sudo chmod 600 "${CERT_DIR}/privkey.pem"
sudo chmod 644 "${CERT_DIR}/fullchain.pem"

echo ""
echo "✅ 证书生成成功！"
echo "私钥: ${CERT_DIR}/privkey.pem"
echo "证书: ${CERT_DIR}/fullchain.pem"
echo ""
echo "⚠️  注意：此证书仅用于开发/测试环境"
echo "   生产环境请使用 Let's Encrypt 证书"
