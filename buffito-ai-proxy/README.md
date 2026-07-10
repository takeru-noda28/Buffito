# Buffito AI Proxy

Buffito iOS アプリから Gemini API を安全に呼び出す Cloudflare Workers バックエンドです。

## 役割

- Gemini API キーを iOS アプリに含めない
- 無料ユーザーは 1日10回、Pro ユーザーはアプリ側の回数制限なしにする
- Pro ユーザーには運用保護用の隠し上限を 1日200回で置く
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
https://buffito-ai-proxy.<your-subdomain>.workers.dev/api/chat
```

この URL を Phase 2 の iOS 側 `AIBackendURL` に設定します。
