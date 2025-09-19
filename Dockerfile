# 1. Flask 用のベースイメージ
FROM python:3.11-slim AS backend

WORKDIR /app

# Flask の依存をインストール
COPY flask_back/ flask_back/
RUN pip install --no-cache-dir flask flask-cors pandas gunicorn

# 2. Flutter Web のビルドをコピー
COPY flutter_front/predictor_web/build/web/ flutter_front/predictor_web/build/web/

# 3. Nginx 用イメージ
FROM nginx:alpine

# Nginx 設定をコピー
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Flask アプリを別のコンテナで動かす場合はネットワーク設定が必要
# 今回は同一コンテナで動かす簡易例として supervisor などで Flask と Nginx 両方起動も可能
