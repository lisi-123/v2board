#!/bin/bash

if [ ! -d ".git" ]; then
  echo "Please deploy using Git."
  exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Git is not installed! Please install git and try again."
    exit 1
fi

# 确保当前目录安全
git config --global --add safe.directory "$(pwd)"

# 🔒 强制使用你的 Fork 仓库
git remote set-url origin https://github.com/lisi-123/v2board.git

# 从你的仓库拉取并重置到 master
git fetch origin && git reset --hard origin/master

# 更新 Composer
rm -rf composer.lock composer.phar
wget https://github.com/composer/composer/releases/latest/download/composer.phar -O composer.phar
php composer.phar update -vvv

# 检查 PHP 版本并处理 webman
php_main_version=$(php -v | head -n 1 | cut -d ' ' -f 2 | cut -d '.' -f 1)
if [ "$php_main_version" -ge 8 ]; then
    php composer.phar require joanhey/adapterman
    if ! php -m | grep -q "pcntl"; then
        echo "Adding pcntl extension to cli-php.ini"
        sed -i '/extension=redis.so/a extension=pcntl.so' cli-php.ini
    fi
    php -c cli-php.ini webman.php stop
    echo "Webman stopped. Please restart it by yourself."
fi

php artisan v2board:update

if [ -f "/etc/init.d/bt" ]; then
  chown -R www "$(pwd)"
fi

