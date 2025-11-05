# 使用 Python 3.13 官方镜像作为基础镜像
FROM python:3.13-slim

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_SYSTEM_PYTHON=1

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    libpcre3 \
    libpcre3-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装 uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# 复制项目文件
COPY pyproject.toml uv.lock ./
COPY demo ./demo
COPY manage.py uwsgi.ini entrypoint.sh ./

# 同步依赖（使用 uv sync）
RUN uv sync --frozen --no-dev

# 收集静态文件
RUN uv run python manage.py collectstatic --noinput || true

# 创建日志目录
RUN mkdir -p /var/log/uwsgi

# 暴露端口
EXPOSE 8000

# 设置启动脚本
RUN chmod +x /app/entrypoint.sh

# 启动应用
CMD ["/app/entrypoint.sh"]
