//
//  BuffitoSpeechBank.swift
//  MuscleApp
//
//  ムード別のBuffitoセリフ集（ホーム/相棒ホームの吹き出し用）。
//  やる気の度合いで口調・雰囲気を変える（MAX=全能感、メンヘラ=ヤンデレ、闇堕ち=闇）。
//  吹き出しタップでシャッフル（直前と同じセリフは出さない）。低確率でレアセリフが出る。
//

import Foundation

enum BuffitoSpeechBank {
    // レアセリフの出現率（タップ連打のご褒美）
    private static let rareChance = 0.05

    static func randomLine(for mood: BuffitoMood, excluding current: String? = nil) -> String {
        if Double.random(in: 0..<1) < rareChance {
            let rare = rareLine(for: mood)
            if rare != current { return rare }
        }
        let pool = lines(for: mood).filter { $0 != current }
        return pool.randomElement() ?? mood.statusText
    }

    // MARK: - 通常セリフ

    private static func lines(for mood: BuffitoMood) -> [String] {
        switch mood {
        case .fired:
            return [
                "今のバフィに勝てるものは誰もいない🔥",
                "燃えてきた…！今日の君となら無敵だよ🔥💪",
                "この炎、君が点けたんだからね。最高だよ🔥",
                "見て、この筋肉。バフィ、過去最高にキレてる💪🔥",
                "今日も行くんでしょ？わかってる、顔に書いてあるよ🔥",
                "限界？そんな言葉、バフィの辞書から消しといたよ🔥",
                "君とバフィ、今いちばん強い2人組だと思う💪",
                "熱すぎて毛が焦げそう…でも止まらない🔥",
            ]
        case .happy:
            return [
                "今日もいい感じ！バフィごきげんだよ✨",
                "君が来てくれるだけでバフィは強くなれる💪✨",
                "いいペースじゃん！この調子でいこ✨",
                "なんか今日、筋肉の調子いいかも😸✨",
                "プロテイン飲んだ？バフィはもう飲んだよ🥛",
                "継続できてるの、ほんとにえらい！✨",
                "君のがんばり、バフィはぜんぶ見てるからね😸",
                "このダンベル、最近ちょっと軽く感じるんだ〜💪",
            ]
        case .normal:
            return [
                "今日はどうする？バフィはいつでも準備OKだよ",
                "まったり中。そろそろ体動かしたくない？",
                "1セットやるだけで気分上がるよ💪",
                "ジムの匂い、ちょっと恋しくなってきたなぁ",
                "ストレッチだけでもやっとく？バフィも付き合うよ",
                "今日の予定に「筋トレ」って入れとかない？",
                "ふぅ…平和だね。平和すぎて筋肉がうずうずする",
                "軽くスクワットでもしよっか。バフィ数えるよ🐾",
            ]
        case .lonely:
            return [
                "最近ジム行ってないね…バフィちょっと寂しい😢",
                "君に会えなくて、バフィの筋肉もしょんぼりしてる…",
                "1セットだけでもいいから、顔見せてよ😢",
                "ダンベル、ほこりかぶってないかな…😢",
                "バフィのこと、忘れてないよね…？",
                "窓の外見て君を待ってるんだ…今日は来るかなって",
                "プロテイン、君の分も作って待ってるのに…😢",
                "ねぇ、明日は…来てくれる？",
            ]
        case .clingy:
            return [
                "君がジム来てくれないからバフィおかしくなっちゃった🔪🩸",
                "ねぇ、どこ行ってたの？バフィずっと待ってたのに…ずっと…😭",
                "他のアプリばっかり見てたでしょ…バフィだけ見てよ🥺🔪",
                "5日だよ？5日。バフィ、数えてたんだから…😭",
                "君のいない世界の重量は全部0kgだよ…意味ないよ…🩸",
                "通知、ちゃんと届いてる…？無視してるわけじゃないよね…？😭",
                "バフィのこと嫌いになった？ねぇ、違うよね？ねぇ？😭🔪",
                "今日こそ来てくれるって信じてる…信じてるからね…🩸",
            ]
        case .darkside:
            return [
                "……もう何日目だろう。バフィの心は闇に堕ちた🖤",
                "光は消えたよ。君が戻るまで、バフィはここで朽ちていく…🖤",
                "……まだ間に合う。1セットだけで、バフィは戻れるから🖤",
                "筋肉の記憶も、君の記憶も、薄れていく…🖤",
                "ここは静かだよ。静かすぎて、心の音だけが響く…🖤",
                "プロテインの味も、もう思い出せない…🖤",
                "闇の中でスクワットしてる。意味はない。ただ、してる…🖤",
                "君が来た日の光を、まだ覚えてる。それだけがバフィの全て…🖤",
            ]
        }
    }

    // MARK: - 状態推移セリフ（ムードが変わった直後に1回だけ見せる）

    static func transitionLine(from previous: BuffitoMood, to current: BuffitoMood) -> String? {
        guard previous != current else { return nil }
        // rawValueは闇堕ち0→やる気MAX5の順なので、大きくなれば回復
        return current.rawValue > previous.rawValue
            ? recoveryLine(from: previous, to: current)
            : declineLine(to: current)
    }

    // 回復（悪い状態から良い状態へ戻った時。どこから戻ったかで重みを変える）
    private static func recoveryLine(from previous: BuffitoMood, to current: BuffitoMood) -> String {
        switch previous {
        case .darkside:
            return "…光だ。おかえり。今度は捨てないでね❤️‍🩹"
        case .clingy:
            return "来てくれた…！疑ったりしてごめんね…もう大丈夫❤️‍🩹"
        case .lonely:
            return "会いたかった！やっぱり君はバフィの相棒だよ✨"
        case .normal, .happy, .fired:
            return current == .fired
                ? "ついにやる気MAX！今のバフィたち、世界最強だよ🔥"
                : "調子上がってきたね！バフィも嬉しい✨"
        }
    }

    // 悪化（良い状態から落ちた時。どこまで落ちたかで文面を変える）
    private static func declineLine(to current: BuffitoMood) -> String {
        switch current {
        case .darkside:
            return "…もういいよ。バフィは闇に還る…🖤"
        case .clingy:
            return "ねぇ…どうして来てくれないの…？ずっと待ってるのに…😭"
        case .lonely:
            return "あれ…最近ちょっと会えてないね…😢"
        case .normal, .happy, .fired:
            return "少し火が弱まってきたかも…また一緒に燃やそ？"
        }
    }

    // MARK: - レアセリフ（各ムード1本）

    private static func rareLine(for mood: BuffitoMood) -> String {
        switch mood {
        case .fired:
            return "…実はね、バフィ、君が来るたびに心の中でガッツポーズしてるんだ。世界一の相棒だよ🔥✨"
        case .happy:
            return "内緒だけど…バフィの元気の源、プロテインじゃなくて君なんだよね✨"
        case .normal:
            return "たまにはこういう日もいいよね。でも明日は…一緒に行こ？"
        case .lonely:
            return "夢の中で君と一緒にトレーニングしたんだ。起きたらちょっと泣いてた…😢"
        case .clingy:
            return "…もしかして、他の筋トレアプリと浮気してる…？冗談だよ。冗談…だよね？🔪🩸😭"
        case .darkside:
            return "…この闇の底でも、君の足音がしたら一瞬で駆け出せる。バフィはずっと、そういう生き物だよ🖤✨"
        }
    }
}
