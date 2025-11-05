#!/bin/bash

# 等待数据库就绪
echo "Waiting for database..."
sleep 5

# 执行数据库迁移
echo "Running database migrations..."
uv run python manage.py migrate --noinput

# 收集静态文件
echo "Collecting static files..."
uv run python manage.py collectstatic --noinput

# 启动 uwsgi
echo "Starting uWSGI..."
exec uv run uwsgi --ini uwsgi.ini
