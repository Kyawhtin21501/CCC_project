#!/bin/sh
# Flaskをバックグラウンドで起動
gunicorn -w 4 -b 0.0.0.0:$PORT flask_back.app:app &

# Nginxをフォアグラウンドで起動
nginx -g "daemon off;"
