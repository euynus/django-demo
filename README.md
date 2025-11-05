# Django Demo

这是一个使用 uv 包管理工具创建的 Django 4.2.24 项目，支持 uwsgi 和 Docker Compose 部署，支持宿主机 Nginx 反向代理和 HTTPS。

## 项目结构

```
django-demo/
├── demo/                           # Django 项目目录
│   ├── __init__.py
│   ├── asgi.py
│   ├── settings.py                 # 项目设置（支持环境变量）
│   ├── urls.py
│   └── wsgi.py
├── .venv/                          # 虚拟环境（uv 管理）
├── static/                         # 静态文件目录
├── media/                          # 媒体文件目录
├── manage.py                       # Django 管理脚本
├── uwsgi.ini                       # uWSGI 配置文件
├── Dockerfile                      # Docker 镜像构建文件
├── docker-compose.yml              # Docker Compose 配置
├── entrypoint.sh                   # Docker 容器启动脚本
├── nginx-host.conf                 # 宿主机 Nginx 配置（支持 HTTPS）
├── nginx-docker.conf.example       # Docker 容器内 Nginx 配置示例
├── generate-self-signed-cert.sh    # 自签名证书生成脚本
├── SSL-SETUP.md                    # SSL/HTTPS 配置详细指南
├── Makefile                        # 快捷命令
├── .env.example                    # 环境变量示例
├── pyproject.toml                  # 项目依赖配置
└── uv.lock                         # 依赖锁定文件
```

## 本地开发

### 前提条件

- Python 3.13+
- uv 包管理工具

### 安装依赖

```bash
uv sync
```

### 运行开发服务器

```bash
uv run python manage.py runserver
```

访问 http://127.0.0.1:8000

### 数据库迁移

```bash
uv run python manage.py makemigrations
uv run python manage.py migrate
```

### 创建超级用户

```bash
uv run python manage.py createsuperuser
```

## uWSGI 部署

### 本地测试 uWSGI

```bash
uv run uwsgi --ini uwsgi.ini
```

## Docker Compose 部署

### 构建并启动服务

```bash
# 使用 Makefile 快捷命令
make docker-up

# 或使用 docker-compose 命令
docker-compose up -d --build
```

### 查看服务状态

```bash
docker-compose ps
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看 web 服务日志
docker-compose logs -f web

# 查看数据库日志
docker-compose logs -f db
```

### 执行数据库迁移

```bash
# 使用 Makefile
make docker-migrate

# 或使用 docker-compose
docker-compose exec web uv run python manage.py migrate
```

### 创建超级用户

```bash
make docker-createsuperuser
# 或
docker-compose exec web uv run python manage.py createsuperuser
```

### 收集静态文件

```bash
make docker-collectstatic
# 或
docker-compose exec web uv run python manage.py collectstatic --noinput
```

### 停止服务

```bash
make docker-down
# 或
docker-compose down
```

### 停止并删除数据卷

```bash
docker-compose down -v
```

## 宿主机 Nginx + HTTPS 部署

本项目配置为使用**宿主机的 Nginx** 作为反向代理，支持 HTTPS。

### 快速开始

1. **启动 Docker 容器**

```bash
docker-compose up -d --build
```

容器会在 `127.0.0.1:8000` 监听 uwsgi 请求。

2. **配置 SSL 证书**

**开发环境（自签名证书）：**
```bash
chmod +x generate-self-signed-cert.sh
sudo ./generate-self-signed-cert.sh your-domain.com
```

**生产环境（Let's Encrypt）：**
```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

详细的 SSL 配置说明请查看 [SSL-SETUP.md](SSL-SETUP.md)

3. **配置 Nginx**

```bash
# 复制配置文件
sudo cp nginx-host.conf /etc/nginx/sites-available/django-demo

# 编辑配置文件，修改域名和路径
sudo nano /etc/nginx/sites-available/django-demo

# 需要修改的内容：
# - server_name: 修改为你的域名
# - ssl_certificate: SSL 证书路径
# - ssl_certificate_key: SSL 私钥路径
# - location /static/: 修改为实际的静态文件路径
# - location /media/: 修改为实际的媒体文件路径

# 启用配置
sudo ln -s /etc/nginx/sites-available/django-demo /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重载 Nginx
sudo systemctl reload nginx
```

4. **配置防火墙**

```bash
# Ubuntu/Debian
sudo ufw allow 'Nginx Full'

# CentOS/RHEL
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

5. **访问应用**

- HTTPS: `https://your-domain.com`
- Django Admin: `https://your-domain.com/admin`

### Nginx 配置要点

`nginx-host.conf` 配置文件包含：

- ✅ HTTP 到 HTTPS 自动重定向
- ✅ SSL/TLS 安全配置
- ✅ uwsgi 协议代理到 Django
- ✅ 静态文件和媒体文件服务
- ✅ 安全头配置（HSTS, X-Frame-Options 等）
- ✅ Gzip 压缩
- ✅ 缓存控制
- ✅ 日志记录

### 服务访问

**仅使用 Docker（无 Nginx）：**
- Django 应用: http://localhost:8000

**使用宿主机 Nginx（推荐）：**
- HTTP（自动重定向到 HTTPS）: http://your-domain.com
- HTTPS: https://your-domain.com
- Django Admin: https://your-domain.com/admin

## 环境变量

在 `docker-compose.yml` 中可以配置以下环境变量：

- `DEBUG`: 是否开启调试模式（生产环境应设置为 False）
- `SECRET_KEY`: Django 密钥（生产环境应修改为随机字符串）
- `ALLOWED_HOSTS`: 允许访问的主机列表
- `DATABASE_URL`: 数据库连接 URL

## 生产环境注意事项

### 安全配置

1. **修改密钥**
   ```bash
   # 生成随机 SECRET_KEY
   python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
   ```

2. **Django 设置**（`demo/settings.py`）
   ```python
   DEBUG = False
   ALLOWED_HOSTS = ['your-domain.com', 'www.your-domain.com']

   # HTTPS 安全设置
   SECURE_SSL_REDIRECT = True
   SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
   SESSION_COOKIE_SECURE = True
   CSRF_COOKIE_SECURE = True
   SECURE_HSTS_SECONDS = 31536000
   SECURE_HSTS_INCLUDE_SUBDOMAINS = True
   SECURE_HSTS_PRELOAD = True
   ```

3. **数据库**
   - 使用 PostgreSQL（已在 docker-compose.yml 中配置）
   - 修改默认数据库密码
   - 定期备份数据库

4. **SSL/HTTPS**
   - 使用 Let's Encrypt 免费证书（见 [SSL-SETUP.md](SSL-SETUP.md)）
   - 配置自动续期
   - 启用 HSTS

5. **日志和监控**
   - 配置日志轮转
   - 设置错误监控（如 Sentry）
   - 监控服务器资源使用

6. **性能优化**
   - 启用 Nginx Gzip 压缩（已配置）
   - 配置静态文件缓存（已配置）
   - 使用 CDN 加速静态资源
   - 优化数据库查询

7. **防火墙**
   - 只开放必要端口（80, 443）
   - 配置 fail2ban 防止暴力攻击
   - 定期更新系统补丁

## Makefile 快捷命令

```bash
make help              # 显示所有可用命令
make install           # 安装项目依赖
make run               # 运行开发服务器
make migrate           # 执行数据库迁移
make makemigrations    # 创建迁移文件
make createsuperuser   # 创建超级用户
make shell             # 进入 Django shell
make test              # 运行测试
make uwsgi             # 使用 uwsgi 启动
make docker-build      # 构建 Docker 镜像
make docker-up         # 启动服务
make docker-down       # 停止服务
make docker-logs       # 查看日志
make docker-migrate    # Docker 中执行迁移
make docker-shell      # 进入容器 shell
```

## 技术栈

- **语言**: Python 3.13
- **框架**: Django 4.2.24
- **WSGI 服务器**: uWSGI 2.0.31
- **数据库**: PostgreSQL 16
- **Web 服务器**: Nginx（宿主机）
- **容器化**: Docker & Docker Compose
- **包管理**: uv 0.9.7
- **SSL**: Let's Encrypt / 自签名证书
- **反向代理**: Nginx (uwsgi 协议)

## 许可证

MIT
