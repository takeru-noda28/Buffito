//
//  LocalFAQResponder.swift
//  MuscleApp
//
//  定型質問への端末内即答（ルールベースFAQ）。
//  目的：
//  1. API利用回数の節約（無料枠を定型質問で消費しない）
//  2. 健康リスクのある質問（急な減量など）に安全側の回答を確実に返す
//  3. 外部送信ゼロ（プライバシーポリシー上のデータ送信も発生しない）
//  マッチしない質問は nil を返し、呼び出し側がAIサービスへフォールバックする。
//  回答はAIと同じトーン（結論から話す自然な会話文＋絵文字1〜3個）で統一する。
//

import Foundation

// 相棒ホームのマインドマップに並べるFAQ。タップで端末内即答（API消費なし）
struct FAQChip: Identifiable {
    let id = UUID()
    let label: String       // マップのノードに表示する短いラベル
    let question: String    // 回答シートに表示する質問全文
    let makeAnswer: (AIWorkoutContext) -> String

    func answer(context: AIWorkoutContext) -> String {
        makeAnswer(context)
    }
}

enum LocalFAQResponder {

    // これより長い質問は個別相談とみなしてAIに回す（定型質問は短い前提）
    private static let maxFAQMessageLength = 40

    // キーワードグループ：全グループで最低1語ヒットしたらマッチ
    // question はチップに表示する代表質問（keywordGroupsにマッチする文面にしておく）
    private struct FAQEntry {
        let label: String
        let question: String
        let keywordGroups: [[String]]
        let makeAnswer: (AIWorkoutContext) -> String
    }

    /// 相棒ホームのFAQチップ一覧（全て端末内で即答できる質問）
    static let chips: [FAQChip] = entries.map {
        FAQChip(label: $0.label, question: $0.question, makeAnswer: $0.makeAnswer)
    }

    private static let entries: [FAQEntry] = [
        // タンパク質の摂取量
        FAQEntry(
            label: "タンパク質",
            question: "タンパク質は1日どれくらい摂ればいい？",
            keywordGroups: [
                ["タンパク質", "たんぱく質", "蛋白質", "プロテイン"],
                ["何g", "何グラム", "どれくらい", "どのくらい", "量", "摂", "必要"]
            ],
            makeAnswer: { _ in
                """
                筋トレしてるなら、タンパク質は体重1kgあたり1.6〜2.2g/日が目安だよ💪 体重60kgなら約96〜132g。国際スポーツ栄養学会などの指針でも、筋肥大には体重×1.6g以上が推奨されてるんだ。1食20〜30gを3〜5回に分けて、トレーニング後は特に意識してみて✨ 腎臓に持病がある場合は医師に相談してね。
                """
            }
        ),
        // 減量ペース
        FAQEntry(
            label: "減量",
            question: "減量って月に何kgまでがいい？",
            keywordGroups: [
                ["減量", "痩せ", "ダイエット", "減ら", "落と", "絞"],
                ["体重", "kg", "キロ", "脂肪"]
            ],
            makeAnswer: { _ in
                """
                減量は1ヶ月に体重の2〜4%（多くの人で2〜3kg）までが現実的だよ。月5kgは筋肉も減りやすくて急ぎすぎ🐱 週0.5〜1%のペースが筋肉を保ちやすいとされてるし、急な減量はリバウンドと停滞のもと。摂取カロリーを維持より300〜500kcal減らして、タンパク質は体重×2g、筋トレはそのまま続けよう💪 めまいや強い疲労を感じたら減量幅を緩めてね。持病がある場合は医師に相談を。
                """
            }
        ),
        // セット間の休憩時間
        FAQEntry(
            label: "休憩",
            question: "セット間の休憩は何分がいい？",
            keywordGroups: [
                ["休憩", "レスト", "インターバル", "休息"],
                ["何分", "何秒", "どれくらい", "どのくらい", "時間", "目安"]
            ],
            makeAnswer: { _ in
                """
                セット間の休憩は目的で変えるのがコツだよ。筋力狙いなら3〜5分、筋肥大狙いなら1〜2分が目安⏱️ 高重量・低回数は回復優先、中重量・中回数なら短めの休憩も効果的とされてるんだ。メイン種目は2〜3分、補助種目は60〜90秒で試してみて。Buffitoのレストタイマーが使えるよ💪 息が整わないまま次のセットに入らないようにね。
                """
            }
        ),
        // トレーニング頻度
        FAQEntry(
            label: "頻度",
            question: "筋トレは週何回やればいい？",
            keywordGroups: [
                ["頻度", "週何回", "週に何回", "何日おき", "毎日"],
                ["トレ", "筋トレ", "ジム", "鍛"]
            ],
            makeAnswer: { context in
                var answer = """
                同じ部位は週2〜3回、間に48〜72時間の回復を挟むのが目安だよ💪 筋肉はトレーニング後の回復中に成長するから、部位を分ければ週4〜6日やってもOK。全身法なら週3回、分割法なら「押す日/引く日/脚の日」の3分割から始めるのがおすすめ✨ 睡眠不足や強い疲労があるときは、1日休む方が伸びるよ。
                """
                let sessions = context.recent30Days.totalSessions
                if sessions > 0 {
                    answer += "\nちなみに記録だと、直近30日で\(sessions)回トレーニングしてるよ📈"
                }
                return answer
            }
        ),
        // 1RMとは
        FAQEntry(
            label: "1RM",
            question: "1RMってなに？",
            keywordGroups: [
                ["1rm", "ワンレップマックス", "最大挙上"]
            ],
            makeAnswer: { _ in
                """
                1RMは「正しいフォームで1回だけ挙げられる最大重量」のことだよ🏋️ Buffitoは重量×回数から推定1RMを自動計算してて、種目別分析で推移が見られるんだ。実測は怪我のリスクが高いから、8回前後できる重量からの推定値で十分✨ 推定値はあくまで目安だから、フォームが崩れる重量には挑まないでね。
                """
            }
        ),
        // 増量ペース
        FAQEntry(
            label: "増量",
            question: "増量のペースはどれくらい？",
            keywordGroups: [
                ["増量", "バルクアップ", "バルク", "体重増や", "デカく"]
            ],
            makeAnswer: { _ in
                """
                増量は維持カロリー+200〜300kcalで、月0.5〜1kg増のペースが目安だよ💪 急激に増やすと脂肪が増えやすいんだ。タンパク質は増量中も体重×1.6〜2.2gをキープ。週1回同じ条件で体重を測って、増え方に合わせてカロリーを微調整しよう📈 食べるのがつらいときは食事回数を分けてみてね。
                """
            }
        ),
        // 筋肉痛のときどうするか
        FAQEntry(
            label: "筋肉痛",
            question: "筋肉痛の日はトレしていい？",
            keywordGroups: [
                ["筋肉痛"]
            ],
            makeAnswer: { _ in
                """
                強い筋肉痛が残ってる部位は回復優先！別部位のトレーニングか休養に切り替えよう🐱 筋肉痛が残る部位に高強度をかけると回復が遅れやすいんだ。軽い有酸素やストレッチで血流を促して、48〜72時間空けてから再開してみて💪 1週間以上続く痛み・関節の痛み・しびれがある場合は専門家に相談してね。
                """
            }
        )
    ]

    /// 定型質問なら端末内で回答を返す。マッチしなければ nil（AIへフォールバック）
    static func answer(to message: String, context: AIWorkoutContext) -> String? {
        let normalized = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // 長い質問は文脈を含む個別相談の可能性が高いのでAIに任せる
        guard !normalized.isEmpty, normalized.count <= maxFAQMessageLength else {
            return nil
        }

        for entry in entries where matches(normalized, entry: entry) {
            return entry.makeAnswer(context)
        }
        return nil
    }

    private static func matches(_ normalizedMessage: String, entry: FAQEntry) -> Bool {
        entry.keywordGroups.allSatisfy { group in
            group.contains { normalizedMessage.contains($0.lowercased()) }
        }
    }
}
