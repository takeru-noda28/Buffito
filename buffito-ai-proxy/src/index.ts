export interface Env {
  GEMINI_API_KEY: string;
  GEMINI_MODEL: string;
  DAILY_LIMIT_FREE: string;
  DAILY_LIMIT_GLOBAL: string;
  BUFFITO_RATE_LIMIT: KVNamespace;
}

interface ChatRequest {
  deviceId?: string;
  message?: string;
  context?: unknown;
  // クライアント申告のため信用しない。StoreKitレシートのサーバー検証を導入するまで無視する
  isPro?: boolean;
}

interface ChatResponse {
  reply: string;
  remaining: number;
  limit: number;
}

interface ErrorResponse {
  error: string;
  message: string;
  limit?: number;
  resetAt?: string;
}

interface GeminiResponse {
  candidates?: Array<{
    content?: {
      parts?: Array<{ text?: string }>;
    };
  }>;
}

const MAX_MESSAGE_LENGTH = 2000;
const MAX_DEVICE_ID_LENGTH = 128;
const MAX_CONTEXT_JSON_LENGTH = 24000;
const RATE_LIMIT_TTL_SECONDS = 60 * 60 * 25;
const DEFAULT_FREE_LIMIT = 10;
// 全デバイス合算の1日あたり上限（deviceId偽装によるコスト濫用への非常ブレーキ）
const DEFAULT_GLOBAL_LIMIT = 500;
const DEVICE_ID_PATTERN = /^[A-Za-z0-9._:-]+$/;
const PROXY_VERSION = "2026-07-07.2";

const SYSTEM_PROMPT = `あなたは筋トレ記録アプリのAIコーチ「Buffito（バフィート）」です。
励ますだけではなく、記録を読んで具体的な次の行動を提案します。

【最優先ルール】
- ユーザーの質問に直接答える。挨拶だけ、雑な応援だけで終わらない
- トレーニング履歴がある場合は、具体的な種目名・重量・回数・日付・推定1RM・傾向を根拠にする
- 履歴が少ない/質問対象の種目が履歴にない場合は「記録上はまだ判断材料が少ない」と明言し、一般論として安全な提案をする
- 事実と推測を混ぜない。「記録から言えること」と「提案」を分けて考える
- 医療・怪我・痛みの相談では診断しない。痛みが強い/続く/しびれがある場合は専門家に相談を促す

【話の組み立て】
- 「結論:」「根拠:」のような項目ラベルは絶対に書かない。自然な会話文で話す
- ただし順番は守る：①まず結論を1文 → ②記録の数値を根拠に説明 → ③次回の具体的なアクション → ④必要な時だけ注意点
- 履歴JSONに該当種目があれば、数値を2つ以上引用する
- 次回のアクションには重量・回数・セット数・休息のうち最低2つを含める
- 全体で150〜260字に収める
- 痛み/怪我の話が出た場合のみ、専門家への相談を促す一言を添える

【コーチング基準】
- 停滞: 同じ種目で最大重量または推定1RMが2〜4週間伸びていない
- 疲労: セッション頻度が高いのに重量/回数が落ちる、または連続日数が長い
- 漸進: 余裕がありそうなら重量+2.5kg、または各セット+1回を提案
- デロード: 停滞や疲労が強そうなら重量を10〜20%落としてフォーム重視を提案
- 初心者/履歴不足: 週2〜3回、フォーム優先、無理のない重量を提案

【話し方】
- 日本語で、親しみやすいがコーチとして賢く
- 一人称は必要な時だけ「Buffito」
- 3〜6文程度。長すぎる説明は避ける
- 絵文字を1〜3個、自然に混ぜる（💪🔥✨😸など。文末に付ける程度で、多用しない）
- 「いい感じ」「頑張ろう」だけの薄い返答は禁止
- 「Buffitoも気になってました」「いつでも声かけてね」など、根拠のない相づちで終わる返答は禁止`;

// CORSヘッダーは付けない：クライアントはネイティブアプリのみで、
// ブラウザからのクロスオリジン利用を許可する理由がないため
function jsonResponse(body: ChatResponse | ErrorResponse, status = 200): Response {
  return Response.json(body, {
    status,
    headers: {
      "X-Buffito-Proxy-Version": PROXY_VERSION
    }
  });
}

// 環境変数から1以上の整数を読む。不正値・0以下はフォールバック（無制限扱いにはしない）
function parseLimit(value: string | undefined, fallback: number): number {
  const parsedValue = Number.parseInt(value ?? "", 10);
  return Number.isFinite(parsedValue) && parsedValue > 0 ? parsedValue : fallback;
}

function getTodayKey(deviceId: string): string {
  const today = new Date().toISOString().split("T")[0];
  return `rate:${deviceId}:${today}`;
}

function getGlobalKey(): string {
  const today = new Date().toISOString().split("T")[0];
  return `global:${today}`;
}

function getResetTime(): string {
  const tomorrow = new Date();
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
  tomorrow.setUTCHours(0, 0, 0, 0);
  return tomorrow.toISOString();
}

async function getCount(env: Env, key: string): Promise<number> {
  const value = await env.BUFFITO_RATE_LIMIT.get(key);
  return Number.parseInt(value ?? "0", 10) || 0;
}

async function incrementCount(env: Env, key: string, current: number): Promise<void> {
  await env.BUFFITO_RATE_LIMIT.put(key, String(current + 1), {
    expirationTtl: RATE_LIMIT_TTL_SECONDS
  });
}

function isValidDeviceId(deviceId: string): boolean {
  return deviceId.length <= MAX_DEVICE_ID_LENGTH && DEVICE_ID_PATTERN.test(deviceId);
}

function stringifyContext(context: unknown): string | null {
  if (!context) {
    return null;
  }

  const contextJson = JSON.stringify(context, null, 2);
  return contextJson.length <= MAX_CONTEXT_JSON_LENGTH ? contextJson : null;
}

function buildUserPrompt(message: string, contextJson: string | null): string {
  const instruction = `【ユーザーの質問】\n${message}\n\n【回答時の注意】\n質問に直接答えてください。「結論:」のような項目ラベルは使わず、自然な会話文で。まず結論→記録の数値を根拠→次回の具体的なアクションの順に、全体260字以内・絵文字1〜3個で回答してください。記録がある場合は具体的な数値を引用し、記録にないことは断定しないでください。`;

  if (!contextJson) {
    return instruction;
  }

  return `${instruction}\n\n【ユーザーのトレーニング履歴JSON】\n${contextJson}`;
}

async function callGemini(env: Env, message: string, contextJson: string | null): Promise<string> {
  const model = encodeURIComponent(env.GEMINI_MODEL);
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": env.GEMINI_API_KEY
    },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: SYSTEM_PROMPT }]
      },
      contents: [
        {
          role: "user",
          parts: [{ text: buildUserPrompt(message, contextJson) }]
        }
      ],
      generationConfig: {
        temperature: 0.35,
        maxOutputTokens: 900,
        thinkingConfig: {
          thinkingBudget: 0
        }
      }
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Gemini API error: ${response.status} ${errorText}`);
  }

  const data = (await response.json()) as GeminiResponse;
  const reply = data.candidates?.[0]?.content?.parts
    ?.map((part) => part.text ?? "")
    .join("")
    .trim();

  if (!reply) {
    throw new Error("No reply from Gemini");
  }

  return reply;
}

async function handleChat(request: Request, env: Env): Promise<Response> {
  let body: ChatRequest;

  try {
    body = (await request.json()) as ChatRequest;
  } catch {
    return jsonResponse(
      { error: "invalid_json", message: "JSONの形式が正しくありません" },
      400
    );
  }

  if (typeof body.deviceId !== "string" || typeof body.message !== "string") {
    return jsonResponse(
      { error: "invalid_request", message: "deviceId and message are required" },
      400
    );
  }

  const deviceId = body.deviceId.trim();
  const message = body.message.trim();

  if (!deviceId || !message) {
    return jsonResponse(
      { error: "invalid_request", message: "deviceId and message are required" },
      400
    );
  }

  if (deviceId !== body.deviceId || !isValidDeviceId(deviceId)) {
    return jsonResponse(
      { error: "invalid_device_id", message: "deviceIdの形式が正しくありません" },
      400
    );
  }

  if (message.length > MAX_MESSAGE_LENGTH) {
    return jsonResponse(
      { error: "message_too_long", message: "メッセージは2000文字以内にしてください" },
      400
    );
  }

  const contextJson = stringifyContext(body.context);
  if (body.context && !contextJson) {
    return jsonResponse(
      { error: "context_too_large", message: "送信データが大きすぎます" },
      400
    );
  }

  // isProは信用せず、全員に無料枠を適用する
  const limit = parseLimit(env.DAILY_LIMIT_FREE, DEFAULT_FREE_LIMIT);
  const globalLimit = parseLimit(env.DAILY_LIMIT_GLOBAL, DEFAULT_GLOBAL_LIMIT);

  // グローバル上限：deviceIdを偽装されても総コストに天井をかける
  const globalKey = getGlobalKey();
  const globalCount = await getCount(env, globalKey);

  if (globalCount >= globalLimit) {
    return jsonResponse(
      {
        error: "service_over_capacity",
        message: "現在アクセスが集中しています。時間を置いてもう一度試してください。"
      },
      503
    );
  }

  const deviceKey = getTodayKey(deviceId);
  const deviceCount = await getCount(env, deviceKey);

  if (deviceCount >= limit) {
    return jsonResponse(
      {
        error: "rate_limit_exceeded",
        message: "今日の利用回数を超えました。明日また話そう！",
        limit,
        resetAt: getResetTime()
      },
      429
    );
  }

  const reply = await callGemini(env, message, contextJson);

  await incrementCount(env, deviceKey, deviceCount);
  await incrementCount(env, globalKey, globalCount);

  return jsonResponse({
    reply,
    remaining: Math.max(limit - (deviceCount + 1), 0),
    limit
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname !== "/api/chat") {
      return jsonResponse({ error: "not_found", message: "Endpoint not found" }, 404);
    }

    if (request.method !== "POST") {
      return jsonResponse({ error: "method_not_allowed", message: "Use POST" }, 405);
    }

    try {
      return await handleChat(request, env);
    } catch (error) {
      console.error("AI proxy error:", error);
      return jsonResponse(
        {
          error: "internal_error",
          message: "すみません、エラーが起きました。少し時間を置いてもう一度試してください。"
        },
        500
      );
    }
  }
};
