import Foundation

// 重量・ボリューム表示の共通フォーマッタ
enum WorkoutFormat {
    /// 総ボリュームを千の位区切りで表示（例：5000 → "5,000"）
    static func volume(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: Int(value))) ?? "\(Int(value))"
    }

    /// 重量を表示（60.0 → "60"、62.5 → "62.5"）
    static func weight(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}
