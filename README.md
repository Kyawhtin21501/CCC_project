# Omakase Shift（CCC Project）

飲食店向けのシフト管理・売上予測・自動シフト割当を一体化した Web / モバイルアプリケーションです。スタッフの希望シフト入力、日次レポート、機械学習による売上予測、制約付き最適化によるシフト自動生成を、Flutter フロントエンドと Flask バックエンドで提供します。

## 主な機能

| 機能               | 説明                                                                            |
| ------------------ | ------------------------------------------------------------------------------- |
| **ダッシュボード** | 売上予測グラフ、本日のシフト、日次レポートの概要表示                            |
| **スタッフ管理**   | スタッフの登録・更新・削除（スキルレベル、雇用形態など）                        |
| **希望シフト**     | スタッフごとの日時・時間帯の希望入力                                            |
| **売上予測**       | XGBoost モデルと Open-Meteo 天気データを用いた日次売上予測                      |
| **シフト自動割当** | Google OR-Tools（CP-SAT）による、予測売上・人件費・希望を考慮した最適シフト生成 |
| **日次レポート**   | 営業日ごとの実績・メモの記録と参照                                              |

## 技術スタック

### バックエンド

- **Python 3.11+** / **Flask** / **Flask-CORS**
- **SQLAlchemy** + **PostgreSQL**（本番は [Render](https://render.com) 想定）
- **XGBoost** / **scikit-learn** — 売上予測
- **OR-Tools** — シフト割当の制約最適化
- **Open-Meteo API** — 天気特徴量の取得

### フロントエンド

- **Flutter**（Dart 3.7+）
- **Provider** — テーマ管理
- **http** — REST API 通信
- **fl_chart** / **table_calendar** — グラフ・カレンダー UI

## プロジェクト構成

```
CCC_project/
├── back_end/                 # Flask API
│   ├── app.py                # アプリケーションエントリポイント
│   ├── config/               # 設定
│   ├── models/               # SQLAlchemy モデル
│   ├── routes/               # API ルート（Blueprint）
│   ├── services/             # ビジネスロジック（予測・シフト割当など）
│   ├── data/                 # 学習済みモデル・祝日データなど
│   └── utils/                # DB 接続・バリデーション・ログ
├── frontend/
│   └── flutter_project/      # Flutter アプリ（パッケージ名: omakase_shift）
│       └── lib/
│           ├── main.dart
│           ├── screens/        # 画面（ダッシュボード・シフト・スタッフ）
│           ├── services/       # API クライアント
│           └── widgets/
├── requirements.txt          # Python 依存関係
├── recreate_db.py            # ローカル SQLite 用 DB 再作成スクリプト
└── scripts/                  # ユーティリティスクリプト
```

## セットアップ

### 前提条件

- Python 3.11 以上
- PostgreSQL（本番・開発で DB を使う場合）
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.7 以上（フロントエンド開発時）

### 1. リポジトリのクローン

```bash
git clone https://github.com/Kyawhtin21501/CCC_project.git
cd CCC_project
```

### 2. 環境変数

プロジェクトルートに `.env` を作成し、データベース接続 URL を設定します。

```env
DATABASE_URL=postgresql://user:password@localhost:5432/ccc_db
```

> Render などで `postgres://` 形式の URL が渡される場合、バックエンド側で `postgresql://` に自動変換されます。

初回セットアップと起動の具体的なコマンドは、下記 **[実行コマンド](#実行コマンド)** を参照してください。

---

## 実行コマンド

> 以下のコマンドは、特に記載がない限り **プロジェクトルート**（`CCC_project/`）をカレントディレクトリとして実行します。

### クイックスタート（初回〜起動まで）

```bash
# 1. クローン（未クローンの場合）
git clone https://github.com/Kyawhtin21501/CCC_project.git
cd CCC_project

# 2. バックエンド：仮想環境・依存関係
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. .env に DATABASE_URL を設定したあと、API サーバー起動
python -m back_end.app

# 4. 別ターミナルでフロントエンド起動
cd frontend/flutter_project
flutter pub get
flutter run
```

| 用途                     | コマンド                                     |
| ------------------------ | -------------------------------------------- |
| 仮想環境を有効化         | `source venv/bin/activate`                   |
| バックエンド起動（開発） | `python -m back_end.app`                     |
| フロントエンド起動       | `cd frontend/flutter_project && flutter run` |
| 依存関係の再インストール | `pip install -r requirements.txt`            |

---

### バックエンド

```bash
# 仮想環境の作成（初回のみ）
python3 -m venv venv

# 仮想環境の有効化
source venv/bin/activate          # macOS / Linux
# venv\Scripts\activate           # Windows (PowerShell / CMD)

# Python パッケージのインストール
pip install -r requirements.txt

# 開発サーバー起動（ポート 5000）
python -m back_end.app
```

起動後: `http://127.0.0.1:5000`  
初回起動時に SQLAlchemy により DB テーブルが自動作成されます。

**Flask CLI で起動する場合:**

```bash
export FLASK_APP=back_end.app:app   # Windows: set FLASK_APP=back_end.app:app
flask run --host=0.0.0.0 --port=5000 --debug
```

**本番相当（Gunicorn）で起動する場合:**

```bash
gunicorn "back_end.app:app" --bind 0.0.0.0:5000 --workers 2
```

---

### フロントエンド（Flutter）

```bash
cd frontend/flutter_project

# 依存パッケージの取得
flutter pub get

# 開発実行（接続先デバイスを選択）
flutter run

# Web ブラウザで実行
flutter run -d chrome

# iOS シミュレータ（macOS のみ）
flutter run -d ios

# Android エミュレータ
flutter run -d android

# リリースビルド（本番 API に接続）
flutter build apk --release          # Android APK
flutter build ios --release          # iOS（macOS + Xcode が必要）
flutter build web --release          # Web
```

デバッグ時の API ベース URL: `http://127.0.0.1:5000`  
実機から接続する場合は `lib/services/api_services.dart` の `baseUrl` を PC のローカル IP（例: `http://192.168.1.10:5000`）に変更してください。

---

### データベース・テストデータ

```bash
# .env の DATABASE_URL を読み込んで接続確認（recreate_db.py）
python recreate_db.py

# テスト用スタッフ・希望シフトの生成（要: venv 有効化・DB 接続済み）
python scripts/testing_gen.py
```

ローカルで SQLite を使う場合は `recreate_db.py` 内の `DATABASE_URL` を参考に、`back_end/utils/db.py` の接続先を一時的に SQLite に切り替えてください。

---

### API 動作確認（curl）

バックエンド起動後、別ターミナルで以下を実行できます。

```bash
# スタッフ一覧
curl http://127.0.0.1:5000/staff

# 売上予測（期間指定）
curl -X POST http://127.0.0.1:5000/pred_sales \
  -H "Content-Type: application/json" \
  -d '{"start_date": "2025-05-01", "end_date": "2025-05-07"}'

# シフト自動割当
curl -X POST http://127.0.0.1:5000/shift_ass \
  -H "Content-Type: application/json" \
  -d '{"start_date": "2025-05-01", "end_date": "2025-05-07"}'

# 割当シフト取得（クエリパラメータ）
curl "http://127.0.0.1:5000/shift_ass_data_main?start_date=2025-05-01&end_date=2025-05-07"

# 希望シフト一覧
curl http://127.0.0.1:5000/shift_pre

# 日次レポート一覧
curl http://127.0.0.1:5000/daily_report
```

---

### よく使う開発コマンド

```bash
# Python 依存の一覧を更新（開発者向け）
pip freeze > requirements.txt

# Flutter の静的解析
cd frontend/flutter_project && flutter analyze

# Flutter テスト実行
cd frontend/flutter_project && flutter test

# 仮想環境の終了
deactivate
```

## API エンドポイント（概要）

| メソッド | パス                    | 説明                                    |
| -------- | ----------------------- | --------------------------------------- |
| `GET`    | `/staff`                | スタッフ一覧                            |
| `GET`    | `/staff/<id>`           | スタッフ詳細                            |
| `POST`   | `/staff`                | スタッフ登録                            |
| `PATCH`  | `/staff/<id>`           | スタッフ更新                            |
| `DELETE` | `/staff/<id>`           | スタッフ削除                            |
| `GET`    | `/shift_pre`            | 希望シフト一覧                          |
| `POST`   | `/shift_pre`            | 希望シフト登録                          |
| `POST`   | `/pred_sales`           | 指定期間の売上予測                      |
| `POST`   | `/pred_sales_dash`      | ダッシュボード用（直近 1 週間）売上予測 |
| `POST`   | `/shift_ass`            | シフト自動割当の実行・DB 保存           |
| `GET`    | `/shift_ass_data_main`  | 期間指定で割当シフト取得                |
| `GET`    | `/shift_ass_dash_board` | ダッシュボード用シフト取得              |
| `GET`    | `/daily_report`         | 日次レポート一覧                        |
| `POST`   | `/daily_report`         | 日次レポート登録                        |

リクエスト・レスポンスの日付形式は `YYYY-MM-DD` です。

## シフト自動割当の流れ

1. **売上予測** — 祝日フラグ・曜日・季節・天気などを特徴量に、学習済み XGBoost モデル（`back_end/data/xgb_sales_model.joblib`）で日次売上を予測
2. **需要の時間帯分解** — 予測売上を時間帯ごとの需要に換算
3. **制約付き最適化** — スタッフのスキルレベル・雇用形態・希望シフト・人件費上限などを OR-Tools CP-SAT で満たしつつシフトを決定
4. **保存** — 結果を `shift_ass` テーブルに永続化

## データ・モデル

- `back_end/data/xgb_sales_model.joblib` — 売上予測用 XGBoost モデル
- `back_end/data/festival_date.json` — 祝日・イベント日（月-日形式）
- `combined_data.csv` / `staff_data.csv` など — 学習・検証用の参考データ

## 本番デプロイ

バックエンドは Render 上の PostgreSQL と連携する想定で実装されています。

1. Render ダッシュボードで環境変数 `DATABASE_URL` を設定
2. 以下のコマンドで WSGI サーバーを起動

```bash
pip install -r requirements.txt
gunicorn "back_end.app:app" --bind 0.0.0.0:$PORT --workers 2
```

> Render では `$PORT` が自動で渡されます。ローカル検証時は `--bind 0.0.0.0:5000` などに置き換えてください。

## ライセンス

本リポジトリのライセンスは未設定です。利用・再配布の際はリポジトリ管理者に確認してください。

## 関連リンク

- 本番 API: `https://ccc-project-1.onrender.com`
- Flutter アプリ名: **omakase_shift**（表示名: 「今日もお疲れさま〜」）
