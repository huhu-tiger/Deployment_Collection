#!/bin/bash
# MySQL 健康检查脚本
# 使用环境变量 MYSQL_ROOT_PASSWORD（MySQL 官方镜像会自动设置）
mysqladmin ping -h localhost -uroot -p"$MYSQL_ROOT_PASSWORD" --silent 2>/dev/null
exit $?

