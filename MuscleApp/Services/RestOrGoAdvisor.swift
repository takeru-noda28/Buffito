//
//  RestOrGoAdvisor.swift
//  MuscleApp
//
//  「休む？行く？」相談のローカル判定ロジック。
//  疲労感の自己申告に記録データ（連続日数・昨日のボリューム・直近7日の頻度）を
//  組み合わせ、3段階（休む/軽め/行く）＋根拠チップで判定する。
//  AIは使わない（体調に関わる相談なので、安全側の固定回答で完結させる）。
//

import Foundation

// 疲労感の3択（シートのボタンと1対1対応）
enum FatigueLevel: CaseIterable, Identifiable {
    case fresh
    case normal
    case tired

    var id: Self { self }

    var label: String {
        switch self {
        case .fresh: return "元気！"
        case .normal: return "ふつう"
        case .tired: return "疲れてる"
        }
    }

    var iconName: String {
        switch self {
        case .fresh: return "bolt.fill"
        case .normal: return "face.smiling"
        case .tired: return "zzz"
        }
    }
}

// 判定の3段階
enum RestOrGoVerdict {
    case rest   // しっかり休む
    case light  // 空いてる部位を軽めならOK
    case go     // 全力で行く
}

struct RestOrGoAdvice {
    let verdict: RestOrGoVerdict
    let message: String
    let evidence: [String]  // 判定根拠のチップ表示用（例：「3日連続」）
}

enum RestOrGoAdvisor {
    // 元気でもこの日数連続していたら軽めを勧める
    private static let overworkStreakDays = 5
    // ふつうの疲れなら、この日数連続で軽めを勧める
    private static let cautionStreakDays = 3
    // これ以上空いていたら「久しぶり」として背中を押す
    private static let longGapDays = 3
    // 昨日のボリュームが平均の何倍以上なら「重めだった」とみなすか
    private static let heavyLoadRatio = 1.3
    // 直近7日でこの日数以上トレしていたら詰め込みすぎとみなす
    private static let busyWeekDays = 5
    // ボリューム平均の計算対象期間
    private static let averageWindowDays = 30

    // 記録から拾う判定材料
    private struct Signals {
        let streak: Int
        let gapDays: Int?          // nil = 記録なし
        let yesterdayVolume: Double
        let averageVolume: Double  // 直近30日の「トレした日」あたり平均ボリューム
        let weekDays: Int          // 直近7日のトレ日数

        var yesterdayLoadRatio: Double? {
            guard yesterdayVolume > 0, averageVolume > 0 else { return nil }
            return yesterdayVolume / averageVolume
        }

        var wasHeavyYesterday: Bool {
            (yesterdayLoadRatio ?? 0) >= RestOrGoAdvisor.heavyLoadRatio
        }
    }

    static func advise(
        fatigue: FatigueLevel,
        allSets: [WorkoutSet],
        referenceDate: Date = Date()
    ) -> RestOrGoAdvice {
        let signals = collectSignals(allSets: allSets, referenceDate: referenceDate)
        let (verdict, message) = judge(fatigue: fatigue, signals: signals)
        return RestOrGoAdvice(verdict: verdict, message: message, evidence: buildEvidence(signals))
    }

    // MARK: - 判定

    private static func judge(fatigue: FatigueLevel, signals: Signals) -> (RestOrGoVerdict, String) {
        switch fatigue {
        case .tired: return tiredAdvice(signals)
        case .normal: return normalAdvice(signals)
        case .fresh: return freshAdvice(signals)
        }
    }

    // 疲れている日は記録に関係なく休養（安全側に倒す）
    private static func tiredAdvice(_ signals: Signals) -> (RestOrGoVerdict, String) {
        if signals.streak >= cautionStreakDays || signals.wasHeavyYesterday {
            return (.rest, "ここまでよくがんばってる！疲れは体からのサインだから、今日は思い切って休もう🛌 筋肉は休んでる間に育つよ")
        }
        return (.rest, "疲れてる日は休むのが正解🛌 休むのも立派なトレーニングだよ。気になるならストレッチだけでもOK")
    }

    private static func normalAdvice(_ signals: Signals) -> (RestOrGoVerdict, String) {
        if signals.streak >= cautionStreakDays {
            return (.light, "\(signals.streak)日連続で疲れも積み重なってる頃。今日は空いてる部位を軽めにやるのがちょうどいいよ🐱")
        }
        if signals.wasHeavyYesterday {
            return (.light, "昨日はいつもより重めのボリュームだったみたい。今日は軽めか別部位にして回復に回そう🐱")
        }
        if signals.weekDays >= busyWeekDays {
            return (.light, "直近7日で\(signals.weekDays)日もトレしてる！今日は軽めにして疲れを抜くのがおすすめ🐱")
        }
        if let gap = signals.gapDays, gap >= longGapDays {
            return (.go, "\(gap)日空いて体は回復済み。いつも通りのメニューで行こう💪")
        }
        return (.go, "その調子なら行って大丈夫💪 無理せずいつも通りのメニューでいこう")
    }

    private static func freshAdvice(_ signals: Signals) -> (RestOrGoVerdict, String) {
        if signals.streak >= overworkStreakDays {
            return (.light, "元気なのはすごい！でももう\(signals.streak)日連続だよ🐱 オーバーワーク防止に、今日は軽めに抑えるのが賢い選択")
        }
        if let gap = signals.gapDays, gap >= longGapDays {
            return (.go, "\(gap)日ぶりのトレーニング、体も回復済みでベストコンディション🔥 今日は全力でいこう💪")
        }
        return (.go, "元気なら迷わず行こう🔥 いいトレーニングになりそうだね💪")
    }

    // MARK: - 判定材料の収集

    private static func collectSignals(allSets: [WorkoutSet], referenceDate: Date) -> Signals {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)
        let streak = StreakTracker.calculate(sets: allSets, referenceDate: referenceDate).current
        // 記録がない場合は日数に言及しない（daysSinceLastWorkoutはInt.maxを返す）
        let gapDays: Int? = allSets.isEmpty
            ? nil
            : StreakTracker.daysSinceLastWorkout(sets: allSets, referenceDate: referenceDate)

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let averageCutoff = calendar.date(byAdding: .day, value: -averageWindowDays, to: today),
              let weekCutoff = calendar.date(byAdding: .day, value: -6, to: today) else {
            return Signals(streak: streak, gapDays: gapDays, yesterdayVolume: 0, averageVolume: 0, weekDays: 0)
        }

        var yesterdayVolume = 0.0
        var volumeByDay: [Date: Double] = [:]
        var weekDays = Set<Date>()
        for set in allSets {
            let day = calendar.startOfDay(for: set.date)
            let volume = set.weight * Double(set.reps)
            if day == yesterday { yesterdayVolume += volume }
            if day >= averageCutoff { volumeByDay[day, default: 0] += volume }
            if day >= weekCutoff { weekDays.insert(day) }
        }
        let averageVolume = volumeByDay.isEmpty
            ? 0
            : volumeByDay.values.reduce(0, +) / Double(volumeByDay.count)

        return Signals(
            streak: streak,
            gapDays: gapDays,
            yesterdayVolume: yesterdayVolume,
            averageVolume: averageVolume,
            weekDays: weekDays.count
        )
    }

    // MARK: - 根拠チップ

    private static func buildEvidence(_ signals: Signals) -> [String] {
        var chips: [String] = []
        if signals.streak >= 2 {
            chips.append("\(signals.streak)日連続")
        }
        if let ratio = signals.yesterdayLoadRatio {
            chips.append("昨日\(WorkoutFormat.volume(signals.yesterdayVolume))kg（平均×\(String(format: "%.1f", ratio))）")
        } else if let gap = signals.gapDays, gap >= 2 {
            chips.append("前回から\(gap)日")
        }
        if signals.weekDays >= 1 {
            chips.append("直近7日で\(signals.weekDays)日")
        }
        return chips
    }

}
