import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import worker, { type Env } from "./index";

class MemoryKV {
  values = new Map<string, string>();

  async get(key: string): Promise<string | null> {
    return this.values.get(key) ?? null;
  }

  async put(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }
}

function createEnv(limitFree = "10", limitGlobal = "500"): Env {
  return {
    GEMINI_API_KEY: "test-api-key",
    GEMINI_MODEL: "gemini-2.5-flash",
    DAILY_LIMIT_FREE: limitFree,
    DAILY_LIMIT_GLOBAL: limitGlobal,
    BUFFITO_RATE_LIMIT: new MemoryKV() as unknown as KVNamespace
  };
}

function createRequest(body: unknown, method = "POST"): Request {
  return new Request("https://example.com/api/chat", {
    method,
    headers: { "Content-Type": "application/json" },
    body: method === "POST" ? JSON.stringify(body) : undefined
  });
}

describe("Buffito AI proxy", () => {
  beforeEach(() => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        Response.json({
          candidates: [
            {
              content: {
                parts: [{ text: "Buffitoだよ。ベンチプレス80kg、いい感じです💪" }]
              }
            }
          ]
        })
      )
    );
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("returns a Gemini reply and decrements the free remaining count", async () => {
    const response = await worker.fetch(
      createRequest({
        deviceId: "device-1",
        message: "ベンチプレスのコツは？",
        context: {
          recent_30days: {
            exercises: {
              "ベンチプレス": { max_weight: 80 }
            }
          }
        },
        isPro: false
      }),
      createEnv()
    );

    expect(response.status).toBe(200);
    expect(response.headers.get("X-Buffito-Proxy-Version")).toBeTruthy();
    expect(await response.json()).toEqual({
      reply: "Buffitoだよ。ベンチプレス80kg、いい感じです💪",
      remaining: 9,
      limit: 10
    });
  });

  it("sends the Gemini API key in a header instead of the URL", async () => {
    const response = await worker.fetch(
      createRequest({ deviceId: "device-1", message: "フォームを見直したい" }),
      createEnv()
    );
    const fetchMock = fetch as unknown as ReturnType<typeof vi.fn>;
    const [url, init] = fetchMock.mock.calls[0];

    expect(response.status).toBe(200);
    expect(String(url)).not.toContain("key=");
    expect(init).toMatchObject({
      headers: {
        "x-goog-api-key": "test-api-key"
      }
    });
  });

  it("joins multiple Gemini text parts into one reply", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () =>
        Response.json({
          candidates: [
            {
              content: {
                parts: [{ text: "結論: " }, { text: "次回は重量を少し調整しましょう。" }]
              }
            }
          ]
        })
      )
    );

    const response = await worker.fetch(
      createRequest({ deviceId: "device-parts", message: "テスト", isPro: false }),
      createEnv()
    );

    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({
      reply: "結論: 次回は重量を少し調整しましょう。"
    });
  });

  it("blocks free users after the daily limit", async () => {
    const env = createEnv("1");

    const firstResponse = await worker.fetch(
      createRequest({ deviceId: "device-1", message: "こんにちは", isPro: false }),
      env
    );
    const secondResponse = await worker.fetch(
      createRequest({ deviceId: "device-1", message: "もう一回", isPro: false }),
      env
    );

    expect(firstResponse.status).toBe(200);
    expect(secondResponse.status).toBe(429);
    expect(await secondResponse.json()).toMatchObject({
      error: "rate_limit_exceeded",
      limit: 1
    });
  });

  // isProはクライアント申告のため信用せず、無料枠を適用する
  it("ignores client-declared isPro and applies the free limit", async () => {
    const env = createEnv("1");

    const firstResponse = await worker.fetch(
      createRequest({ deviceId: "fake-pro-device", message: "1", isPro: true }),
      env
    );
    const secondResponse = await worker.fetch(
      createRequest({ deviceId: "fake-pro-device", message: "2", isPro: true }),
      env
    );

    expect(firstResponse.status).toBe(200);
    expect(await firstResponse.json()).toMatchObject({
      remaining: 0,
      limit: 1
    });
    expect(secondResponse.status).toBe(429);
  });

  // deviceIdを変えてもグローバル上限で止まる
  it("blocks all devices once the global daily limit is reached", async () => {
    const env = createEnv("10", "2");

    const firstResponse = await worker.fetch(
      createRequest({ deviceId: "device-a", message: "1" }),
      env
    );
    const secondResponse = await worker.fetch(
      createRequest({ deviceId: "device-b", message: "2" }),
      env
    );
    const thirdResponse = await worker.fetch(
      createRequest({ deviceId: "device-c", message: "3" }),
      env
    );

    expect(firstResponse.status).toBe(200);
    expect(secondResponse.status).toBe(200);
    expect(thirdResponse.status).toBe(503);
    expect(await thirdResponse.json()).toMatchObject({
      error: "service_over_capacity"
    });
  });

  // 0や不正値を無制限扱いにしない（フォールバック値を使う）
  it("falls back to defaults when limits are zero or invalid", async () => {
    const env = createEnv("0", "abc");

    const response = await worker.fetch(
      createRequest({ deviceId: "device-1", message: "こんにちは" }),
      env
    );

    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({
      remaining: 9,
      limit: 10
    });
  });

  it("validates required fields and message length", async () => {
    const missingFieldsResponse = await worker.fetch(createRequest({}), createEnv());
    const invalidTypesResponse = await worker.fetch(
      createRequest({ deviceId: 123, message: "こんにちは" }),
      createEnv()
    );
    const longMessageResponse = await worker.fetch(
      createRequest({ deviceId: "device-1", message: "a".repeat(2001) }),
      createEnv()
    );

    expect(missingFieldsResponse.status).toBe(400);
    expect(invalidTypesResponse.status).toBe(400);
    expect(longMessageResponse.status).toBe(400);
  });

  it("validates deviceId format and context size before calling Gemini", async () => {
    const invalidDeviceResponse = await worker.fetch(
      createRequest({ deviceId: "device/../../1", message: "こんにちは" }),
      createEnv()
    );
    const spacedDeviceResponse = await worker.fetch(
      createRequest({ deviceId: "bad id", message: "こんにちは" }),
      createEnv()
    );
    const trimmedDeviceResponse = await worker.fetch(
      createRequest({ deviceId: " device-1 ", message: "こんにちは" }),
      createEnv()
    );
    const largeContextResponse = await worker.fetch(
      createRequest({
        deviceId: "device-1",
        message: "こんにちは",
        context: { payload: "x".repeat(24001) }
      }),
      createEnv()
    );

    expect(invalidDeviceResponse.status).toBe(400);
    expect(spacedDeviceResponse.status).toBe(400);
    expect(trimmedDeviceResponse.status).toBe(400);
    expect(largeContextResponse.status).toBe(400);
    expect(fetch).not.toHaveBeenCalled();
  });

  // ネイティブアプリ専用のためCORSは提供しない（ブラウザからの利用を許可しない）
  it("does not expose CORS headers and rejects OPTIONS", async () => {
    const optionsResponse = await worker.fetch(createRequest({}, "OPTIONS"), createEnv());
    const postResponse = await worker.fetch(
      createRequest({ deviceId: "device-1", message: "テスト" }),
      createEnv()
    );

    expect(optionsResponse.status).toBe(405);
    expect(postResponse.headers.get("Access-Control-Allow-Origin")).toBeNull();
  });
});
