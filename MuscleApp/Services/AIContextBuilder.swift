//
//  AIContextBuilder.swift
//  MuscleApp
//

import Foundation

// AIに送るトレーニング履歴。個人情報は含めない。
struct AIWorkoutContext: Codable {
    let recent30Days: Recent30Days
    let streakCurrent: Int
    let streakLongest: Int

    enum CodingKeys: String, CodingKey {
        case recent30Days = "recent_30days"
        case streakCurrent = "streak_current"
        case streakLongest = "streak_longest"
    }

    struct Recent30Days: Codable {
        let totalSessions: Int
        let exercises: [String: ExerciseSummary]

        enum CodingKeys: String, CodingKey {
            case totalSessions = "total_sessions"
            case exercises
        }
    }

    struct ExerciseSummary: Codable {
        let sessions: Int
        let totalSets: Int
        let totalVolume: Double
        let maxWeight: Double
        let maxOneRM: Double
        let lastDate: String?
        let trend: String
        let recentSets: [RecentSet]
        let bestSet: RecentSet?

        enum CodingKeys: String, CodingKey {
            case sessions
            case totalSets = "total_sets"
            case totalVolume = "total_volume"
            case maxWeight = "max_weight"
            case maxOneRM = "max_oneRM"
            case lastDate = "last_date"
            case trend
            case recentSets = "recent_sets"
            case bestSet = "best_set"
        }
    }

    struct RecentSet: Codable {
        let date: String
        let weight: Double
        let reps: Int
        let estimatedOneRM: Double

        enum CodingKeys: String, CodingKey {
            case date
            case weight
            case reps
            case estimatedOneRM = "estimated_oneRM"
        }
    }
}

enum AIContextBuilder {
    private static let recentDays = 30
    private static let maxRecentSetsPerExercise = 5

    static func build(allSets: [WorkoutSet]) -> AIWorkoutContext {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let cutoff = calendar.date(byAdding: .day, value: -(recentDays - 1), to: today) else {
            return empty()
        }

        let recentSets = allSets.filter { $0.date >= cutoff }
        let sessionDays = Set(recentSets.map { calendar.startOfDay(for: $0.date) })
        let exercises = buildExerciseSummaries(recentSets: recentSets, calendar: calendar)
        let streakInfo = StreakTracker.calculate(sets: allSets)

        return AIWorkoutContext(
            recent30Days: .init(totalSessions: sessionDays.count, exercises: exercises),
            streakCurrent: streakInfo.current,
            streakLongest: streakInfo.longest
        )
    }

    private static func buildExerciseSummaries(
        recentSets: [WorkoutSet],
        calendar: Calendar
    ) -> [String: AIWorkoutContext.ExerciseSummary] {
        let groupedByExercise = Dictionary(grouping: recentSets) { set in
            set.exercise?.name ?? ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var summaries: [String: AIWorkoutContext.ExerciseSummary] = [:]
        for (name, sets) in groupedByExercise where !name.isEmpty {
            let sortedSets = sets.sorted { $0.date < $1.date }
            let exerciseSessionDays = Set(sets.map { calendar.startOfDay(for: $0.date) })
            let maxWeight = sets.map(\.weight).max() ?? 0
            let maxOneRM = sets.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
            let lastDate = sets.map(\.date).max().map { formatter.string(from: $0) }
            let totalVolume = sets.reduce(0) { $0 + $1.weight * Double($1.reps) }
            let bestSet = sortedSets.max {
                OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) <
                    OneRMCalculator.estimate(weight: $1.weight, reps: $1.reps)
            }.map { makeRecentSet($0, formatter: formatter) }
            let recentSets = sortedSets.suffix(maxRecentSetsPerExercise).map {
                makeRecentSet($0, formatter: formatter)
            }

            summaries[name] = .init(
                sessions: exerciseSessionDays.count,
                totalSets: sets.count,
                totalVolume: totalVolume,
                maxWeight: maxWeight,
                maxOneRM: maxOneRM,
                lastDate: lastDate,
                trend: estimateTrend(sortedSets: sortedSets),
                recentSets: recentSets,
                bestSet: bestSet
            )
        }
        return summaries
    }

    private static func makeRecentSet(
        _ set: WorkoutSet,
        formatter: DateFormatter
    ) -> AIWorkoutContext.RecentSet {
        AIWorkoutContext.RecentSet(
            date: formatter.string(from: set.date),
            weight: set.weight,
            reps: set.reps,
            estimatedOneRM: OneRMCalculator.estimate(weight: set.weight, reps: set.reps)
        )
    }

    private static func estimateTrend(sortedSets: [WorkoutSet]) -> String {
        guard sortedSets.count >= 4 else { return "insufficient_data" }

        let midpoint = sortedSets.count / 2
        let earlyBest = bestOneRM(in: Array(sortedSets.prefix(midpoint)))
        let recentBest = bestOneRM(in: Array(sortedSets.suffix(sortedSets.count - midpoint)))
        let difference = recentBest - earlyBest

        if difference >= 2.5 {
            return "improving"
        }
        if difference <= -2.5 {
            return "declining"
        }
        return "stable"
    }

    private static func bestOneRM(in sets: [WorkoutSet]) -> Double {
        sets.map { OneRMCalculator.estimate(weight: $0.weight, reps: $0.reps) }.max() ?? 0
    }

    private static func empty() -> AIWorkoutContext {
        AIWorkoutContext(
            recent30Days: .init(totalSessions: 0, exercises: [:]),
            streakCurrent: 0,
            streakLongest: 0
        )
    }
}
