.PHONY: help install run migrate makemigrations createsuperuser shell test docker-build docker-up docker-down docker-logs

help:
	@echo "Django Demo - Available Commands:"
	@echo "  make install         - 安装项目依赖"
	@echo "  make run             - 运行开发服务器"
	@echo "  make migrate         - 执行数据库迁移"
	@echo "  make makemigrations  - 创建迁移文件"
	@echo "  make createsuperuser - 创建超级用户"
	@echo "  make shell           - 进入 Django shell"
	@echo "  make test            - 运行测试"
	@echo "  make uwsgi           - 使用 uwsgi 启动服务"
	@echo "  make docker-build    - 构建 Docker 镜像"
	@echo "  make docker-up       - 启动 Docker Compose 服务"
	@echo "  make docker-down     - 停止 Docker Compose 服务"
	@echo "  make docker-logs     - 查看 Docker 日志"
	@echo "  make docker-migrate  - 在 Docker 容器中执行迁移"
	@echo "  make docker-shell    - 进入 Docker 容器的 shell"

install:
	uv sync

run:
	uv run python manage.py runserver

migrate:
	uv run python manage.py migrate

makemigrations:
	uv run python manage.py makemigrations

createsuperuser:
	uv run python manage.py createsuperuser

shell:
	uv run python manage.py shell

test:
	uv run python manage.py test

uwsgi:
	uv run uwsgi --ini uwsgi.ini

docker-build:
	docker-compose build

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down

docker-logs:
	docker-compose logs -f

docker-migrate:
	docker-compose exec web uv run python manage.py migrate

docker-shell:
	docker-compose exec web /bin/bash

docker-collectstatic:
	docker-compose exec web uv run python manage.py collectstatic --noinput

docker-createsuperuser:
	docker-compose exec web uv run python manage.py createsuperuser
