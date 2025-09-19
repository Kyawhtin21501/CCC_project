#!/bin/sh

# Flask をバックグラウンドで起動
gunicorn -w 4 -b 0.0.0.0:$PORT flask_back.app:app &

# Nginx をフォアグラウンドで起動
nginx -g "daemon off;"
