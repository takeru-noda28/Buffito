//
//  BuffitoHomeView.swift
//  MuscleApp
//
//  Buffitoタブのホーム（相棒ホーム）。
//  キャラカード + 相談メニュー + AIチャット入口をまとめる。
//

import SwiftUI
import SwiftData

// Buffitoタブ内の遷移先
enum BuffitoRoute: Hashable {
    case chat(initialQuestion: String?)
}

// 相談メニューのシート表示（1つのsheetでまとめて管理する）
private enum ConsultSheetItem: Identifiable {
    case today(TodayWorkoutAdvice)
    case stagnation(StagnationAdvice)
    case restOrGo
    case faq(FAQChip)

    // restOrGoは入力（疲労感）をシート内で受けるため、事前計算のadviceを持たない
    private static let restOrGoId = UUID()

    var id: UUID {
        switch self {
        case .today(let advice): return advice.id
        case .stagnation(let advice): return advice.id
        case .restOrGo: return Self.restOrGoId
        case .faq(let chip): return chip.id
        }
    }
}

struct BuffitoHomeView: View {
    // 分析ミニカードのタップで分析タブへ切り替える（タブ切替はContentViewが持つ）
    let onOpenAnalytics: () -> Void

    @Query private var allSets: [WorkoutSet]

    @State private var path = NavigationPath()
    @State private var activeSheet: ConsultSheetItem?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        BuffitoHeroCard(
                            allSets: allSets,
                            onOpenDetail: { path.append(HomeRoute.streakDetail) }
                        )
                        consultSection
                        AnalyticsMiniCard(allSets: allSets, onTap: onOpenAnalytics)
                        chatEntryButton
                        faqSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Buffito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.appBackground, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .navigationDestination(for: BodyPart.self) { part in
                ExerciseListView(bodyPart: part)
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .today:
                    TodayTrainingView()
                case .streakDetail:
                    StreakDetailView()
                case .dayDetail(let date):
                    PastDayView(date: date)
                }
            }
            .navigationDestination(for: BuffitoRoute.self) { route in
                switch route {
                case .chat(let question):
                    AIChatView(initialQuestion: question)
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .today(let advice):
                TodayWorkoutConsultSheet(
                    advice: advice,
                    onRecord: { part in
                        activeSheet = nil
                        path.append(part)
                    },
                    onAskAI: { question in
                        activeSheet = nil
                        path.append(BuffitoRoute.chat(initialQuestion: question))
                    }
                )
            case .stagnation(let advice):
                StagnationConsultSheet(
                    advice: advice,
                    onAskAI: { question in
                        activeSheet = nil
                        path.append(BuffitoRoute.chat(initialQuestion: question))
                    }
                )
            case .restOrGo:
                RestOrGoConsultSheet(
                    allSets: allSets,
                    onSuggestWorkout: {
                        // 「空いてる部位を提案してもらう」→ 今日なにやる？の提案シートへ切替
                        activeSheet = .today(TodayWorkoutAdvisor.advise(allSets: allSets))
                    }
                )
            case .faq(let chip):
                FAQAnswerSheet(chip: chip, allSets: allSets)
            }
        }
    }

    // MARK: - 相談メニュー

    private var consultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("相談する")
                .font(.subheadline)
                .foregroundColor(.gray)

            consultCard(
                title: "今日なにやる？",
                subtitle: "直近の記録からおすすめの部位を提案",
                icon: "figure.strengthtraining.traditional"
            ) {
                activeSheet = .today(TodayWorkoutAdvisor.advise(allSets: allSets))
            }

            consultCard(
                title: "停滞してる種目ある？",
                subtitle: "1RMの伸びから停滞中の種目をチェック",
                icon: "arrow.turn.right.up"
            ) {
                activeSheet = .stagnation(StagnationAdvisor.advise(allSets: allSets))
            }

            consultCard(
                title: "今日は休む？行く？",
                subtitle: "疲れ具合と連続日数からBuffitoが判定",
                icon: "bed.double.fill"
            ) {
                activeSheet = .restOrGo
            }
        }
    }

    private func consultCard(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.orange))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.appCard)
            )
        }
    }

    // MARK: - FAQマインドマップ（端末内で即答・AI利用回数の消費なし）

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("よくある質問")
                .font(.subheadline)
                .foregroundColor(.gray)

            FAQMindMapView(chips: LocalFAQResponder.chips) { chip in
                activeSheet = .faq(chip)
            }
        }
    }

    // MARK: - AIチャット入口

    private var chatEntryButton: some View {
        Button {
            path.append(BuffitoRoute.chat(initialQuestion: nil))
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.orange)
                Text("Buffitoに自由に質問...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appField)
            )
        }
    }
}
