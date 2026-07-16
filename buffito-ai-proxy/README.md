# Buffito AI Proxy

Buffito iOS アプリから Gemini API を安全に呼び出す Cloudflare Workers バックエンドです。

## 役割

- Gemini API キーを iOS アプリに含めない
- クライアント申告の `isPro` は信用せず、全ユーザーに端末単位で1日10回の上限を適用する
- 全端末合計で1日500回の運用上限を適用する
- Buffito 口調のシステムプロンプトを付与する

## 初回セットアップ

```bash
cd /Users/n/Buffito/buffito-ai-proxy
pnpm install
```

Cloudflare にログインします。

```bash
pnpm wrangler login
```

KV namespace を作成します。

```bash
pnpm wrangler kv namespace create BUFFITO_RATE_LIMIT
pnpm wrangler kv namespace create BUFFITO_RATE_LIMIT --preview
```

出力された `id` と `preview_id` を `wrangler.toml` に設定します。

Gemini API キーは Secrets に保存します。

```bash
pnpm wrangler secret put GEMINI_API_KEY
```

## ローカル確認

```bash
pnpm test
pnpm typecheck
pnpm dev
```

別ターミナルで確認します。

```bash
curl -X POST http://localhost:8787/api/chat \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"test-device","message":"こんにちは","context":null,"isPro":false}'
```

## デプロイ

```bash
pnpm deploy
```

デプロイ後の URL:

```text
https://buffito-ai-proxy.buffito.workers.dev/api/chat
```

iOS側の既定URLは `AIService.swift` に定義済みです。環境別に変更する場合はInfo.plistの`AIBackendURL`で上書きします。

## 運用メモ（秘密情報の管理）

AI機能で現在も有効な秘密情報と運用手順をここに集約しています（2026年7月15日更新）。

### 機密情報の所在

| 値 | 場所 | 備考 |
|---|---|---|
| `GEMINI_API_KEY` | Cloudflare Secrets | 値は設定後に確認不可。再設定で上書き |
| KV namespace の `id` / `preview_id` | `wrangler.toml`（git管理外） | 公開用は `wrangler.toml.example` を参照 |
| `AIBackendURL` | iOS の Info.plist（ビルド設定） | 本番Worker URL |

確認コマンド：`pnpm wrangler secret list`

### 定期的にやること

- 3〜6ヶ月に1回 Gemini APIキーをローテーション（前回：2026年6月末に初回設定）
- Cloudflareダッシュボードでアクセスログ・使用量を確認
- Google AI StudioでGemini APIの使用量・割り当てを確認

### APIキーが漏れたら

1. Google AI Studio で当該キーを即無効化
2. 新キーを生成し `pnpm wrangler secret put GEMINI_API_KEY` で上書き
3. Workerの再デプロイは不要（Secretsのみで反映される）
