# SSL/HTTPS 配置指南

本文档说明如何为 Django Demo 项目配置 HTTPS。

## 目录

- [开发环境：自签名证书](#开发环境自签名证书)
- [生产环境：Let's Encrypt 证书](#生产环境lets-encrypt-证书)
- [配置 Nginx](#配置-nginx)
- [验证 HTTPS](#验证-https)

---

## 开发环境：自签名证书

自签名证书适用于本地开发和测试，浏览器会显示"不安全"警告，但功能正常。

### 1. 生成自签名证书

使用提供的脚本快速生成：

```bash
chmod +x generate-self-signed-cert.sh
sudo ./generate-self-signed-cert.sh your-domain.com
```

或手动生成：

```bash
# 创建证书目录
sudo mkdir -p /etc/nginx/ssl/your-domain.com

# 生成证书（有效期 365 天）
sudo openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/your-domain.com/privkey.pem \
    -out /etc/nginx/ssl/your-domain.com/fullchain.pem \
    -subj "/C=CN/ST=State/L=City/O=Organization/CN=your-domain.com"

# 设置权限
sudo chmod 600 /etc/nginx/ssl/your-domain.com/privkey.pem
sudo chmod 644 /etc/nginx/ssl/your-domain.com/fullchain.pem
```

---

## 生产环境：Let's Encrypt 证书

Let's Encrypt 提供免费的、受信任的 SSL 证书，推荐用于生产环境。

### 1. 安装 Certbot

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

**CentOS/RHEL:**
```bash
sudo yum install certbot python3-certbot-nginx
```

**macOS (Homebrew):**
```bash
brew install certbot
```

### 2. 获取证书

#### 方法一：自动配置（推荐）

Certbot 会自动配置 Nginx：

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

按提示输入：
- 电子邮件地址（用于证书过期提醒）
- 同意服务条款
- 选择是否重定向 HTTP 到 HTTPS（推荐选择重定向）

#### 方法二：仅获取证书

如果想手动配置 Nginx：

```bash
sudo certbot certonly --nginx -d your-domain.com -d www.your-domain.com
```

证书文件会保存在：
- 证书：`/etc/letsencrypt/live/your-domain.com/fullchain.pem`
- 私钥：`/etc/letsencrypt/live/your-domain.com/privkey.pem`

### 3. 自动续期

Let's Encrypt 证书有效期为 90 天，需要定期续期。

**测试自动续期：**
```bash
sudo certbot renew --dry-run
```

**设置自动续期 Cron 任务：**
```bash
# 每天凌晨 2:30 检查并续期
echo "30 2 * * * root certbot renew --quiet --post-hook 'systemctl reload nginx'" | sudo tee -a /etc/crontab
```

或使用 systemd timer（Ubuntu 18.04+）：
```bash
sudo systemctl status certbot.timer
```

---

## 配置 Nginx

### 1. 复制配置文件

```bash
sudo cp nginx-host.conf /etc/nginx/sites-available/django-demo
```

### 2. 修改配置

编辑配置文件：
```bash
sudo nano /etc/nginx/sites-available/django-demo
```

修改以下内容：

1. **域名**（多处需要修改）：
   ```nginx
   server_name your-domain.com www.your-domain.com;
   ```

2. **SSL 证书路径**：

   **使用 Let's Encrypt：**
   ```nginx
   ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
   ```

   **使用自签名证书：**
   ```nginx
   ssl_certificate /etc/nginx/ssl/your-domain.com/fullchain.pem;
   ssl_certificate_key /etc/nginx/ssl/your-domain.com/privkey.pem;
   ```

3. **静态文件路径**（修改为实际项目路径）：
   ```nginx
   location /static/ {
       alias /path/to/your/django-demo/static/;
       # ...
   }

   location /media/ {
       alias /path/to/your/django-demo/media/;
       # ...
   }
   ```

### 3. 启用配置

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/django-demo /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重载 Nginx
sudo systemctl reload nginx
```

### 4. 配置防火墙

```bash
# UFW (Ubuntu)
sudo ufw allow 'Nginx Full'
sudo ufw delete allow 'Nginx HTTP'  # 如果只想允许 HTTPS

# firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

---

## 验证 HTTPS

### 1. 启动 Django 应用

```bash
# 启动 Docker 容器
docker-compose up -d

# 检查状态
docker-compose ps
```

### 2. 测试连接

```bash
# 测试 HTTP（应该重定向到 HTTPS）
curl -I http://your-domain.com

# 测试 HTTPS
curl -I https://your-domain.com
```

### 3. 浏览器访问

访问 `https://your-domain.com`

**自签名证书：** 浏览器会显示安全警告，点击"高级" → "继续访问"

**Let's Encrypt 证书：** 应该显示绿色锁图标，表示连接安全

### 4. SSL 评分测试

使用 SSL Labs 测试 SSL 配置质量：
https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com

---

## 优化 SSL 配置（可选）

### 1. 使用更强的 SSL 参数

生成 DH 参数（需要几分钟）：
```bash
sudo openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048
```

在 Nginx 配置中添加：
```nginx
ssl_dhparam /etc/nginx/ssl/dhparam.pem;
```

### 2. 启用 OCSP Stapling（Let's Encrypt）

在 Nginx 配置中添加：
```nginx
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/letsencrypt/live/your-domain.com/chain.pem;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
```

### 3. 更新 Django 配置

编辑 `demo/settings.py`：

```python
# HTTPS 设置
SECURE_SSL_REDIRECT = True  # 强制 HTTPS
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000  # HSTS
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

重启应用：
```bash
docker-compose restart web
```

---

## 故障排查

### 证书错误

```bash
# 检查证书有效期
sudo openssl x509 -in /etc/nginx/ssl/your-domain.com/fullchain.pem -noout -dates

# Let's Encrypt 证书
sudo certbot certificates
```

### Nginx 错误

```bash
# 检查 Nginx 配置
sudo nginx -t

# 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/django-demo-error.log
```

### 连接被拒绝

```bash
# 检查 uwsgi 是否运行
docker-compose ps

# 检查端口监听
sudo netstat -tlnp | grep 8000

# 查看 uwsgi 日志
docker-compose logs -f web
```

### 防火墙问题

```bash
# 检查防火墙状态
sudo ufw status  # Ubuntu
sudo firewall-cmd --list-all  # CentOS

# 确保 443 端口开放
sudo ufw allow 443
```

---

## 相关资源

- [Let's Encrypt 官网](https://letsencrypt.org/)
- [Certbot 文档](https://certbot.eff.org/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [SSL Labs Testing Tool](https://www.ssllabs.com/ssltest/)
- [Django HTTPS 设置](https://docs.djangoproject.com/en/4.2/topics/security/#ssl-https)
