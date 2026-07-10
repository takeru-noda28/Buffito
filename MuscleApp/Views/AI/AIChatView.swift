//
//  AIChatView.swift
//  MuscleApp
//

import SwiftData
import SwiftUI

struct AIChatView: View {
    // 相談メニューから遷移した場合、入力欄に最初からセットする質問文
    var initialQuestion: String? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\AIMessage.timestamp, order: .forward)])
    private var messages: [AIMessage]
    @Query private var allSets: [WorkoutSet]

    @AppStorage("ai_consent_given") private var consentGiven = false

    // サーバーの無料枠と同じ値（初回レスポンスで実値に更新される）
    private static let defaultDailyLimit = 10
    private static let maxMessageLength = 2_000

    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var remaining = -1
    @State private var limit = Self.defaultDailyLimit
    @State private var showConsent = false
    @State private var showRateLimit = false

    private let bottomID = "ai-chat-bottom"

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                messagesScrollView
                inputBar
            }
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            showConsent = !consentGiven
            // 相談からの遷移なら質問文をセット（送信はユーザーが行う＝回数消費を明示的に）
            if let initialQuestion, inputText.isEmpty {
                inputText = initialQuestion
            }
        }
        .sheet(isPresented: $showConsent) {
            AIConsentSheet(
                onAgree: {
                    consentGiven = true
                    showConsent = false
                },
                onCancel: {
                    showConsent = false
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showRateLimit) {
            AIRateLimitView()
        }
    }

    private var headerView: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Buffitoに聞く")
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                if remaining >= 0 {
                    Text("今日の残り \(remaining) / \(limit)回")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.appBackground)
    }

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if messages.isEmpty {
                        emptyStateView
                    }

                    ForEach(messages) { message in
                        messageBubble(message)
                    }

                    if isLoading {
                        loadingBubble
                    }

                    if let errorMessage {
                        errorBubble(errorMessage)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: isLoading) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 14) {
            buffitoAvatar(size: 72)

            Text("Buffitoに相談しよう")
                .font(.headline)
                .foregroundColor(.appTextPrimary)

            Text("トレーニングの悩み、フォームのコツ、停滞打破の相談に答えます。")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 8) {
                suggestionButton("今日のおすすめトレーニングは？")
                suggestionButton("タンパク質は1日どれくらい摂ればいい？")
                suggestionButton("停滞してる種目があれば教えて")
            }
            .padding(.top, 8)
        }
        .padding(.top, 56)
    }

    private var loadingBubble: some View {
        HStack(spacing: 8) {
            buffitoAvatar(size: Self.avatarSize)
            ProgressView()
                .tint(.gray)
            Text("Buffito 考え中...")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Buffitoに質問...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appField)
                )

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(canSend ? Color.orange : Color.gray))
            }
            .disabled(!canSend || isLoading)
        }
        .padding()
        .background(Color.appBackground)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func suggestionButton(_ text: String) -> some View {
        Button { inputText = text } label: {
            Text(text)
                .font(.caption)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.appField))
                .overlay(Capsule().stroke(Color.appBorder, lineWidth: 0.5))
        }
    }

    // LINE風：Buffitoの返信にはキャラアイコンを添える（ユーザー側はアイコンなし）
    private func messageBubble(_ message: AIMessage) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            } else {
                buffitoAvatar(size: Self.avatarSize)
            }

            Text(message.content)
                .font(.subheadline)
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(message.role == .user ? Color.orange : Color.appField)
                )
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }

    // MARK: - Buffitoアバター（丸枠）

    private static let avatarSize: CGFloat = 32

    private func buffitoAvatar(size: CGFloat) -> some View {
        Image("BuffitoAvatar")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.appField, lineWidth: 1))
    }

    private func errorBubble(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(text)
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.15))
        )
    }

    private func sendMessage() async {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        guard userText.count <= Self.maxMessageLength else {
            errorMessage = "質問は\(Self.maxMessageLength)文字以内で入力してください"
            return
        }
        // 未同意なら送信せず、同意画面を出し直す（タブ表示で同意を後回しにした場合）
        guard consentGiven else {
            showConsent = true
            return
        }

        inputText = ""
        errorMessage = nil
        isLoading = true

        let userMessage = AIMessage(role: .user, content: userText)
        modelContext.insert(userMessage)
        modelContext.saveOrLog("ユーザーメッセージ保存")

        let context = AIContextBuilder.build(allSets: allSets)

        // 定型質問は端末内で即答する（API回数を消費せず、外部送信もしない）
        if let localReply = LocalFAQResponder.answer(to: userText, context: context) {
            let aiMessage = AIMessage(role: .assistant, content: localReply)
            modelContext.insert(aiMessage)
            modelContext.saveOrLog("FAQ回答保存")
            isLoading = false
            return
        }

        do {
            let response = try await AIService.shared.sendMessage(
                userText,
                context: context,
                isPro: PremiumManager.shared.isPremium
            )

            let aiMessage = AIMessage(role: .assistant, content: response.reply)
            modelContext.insert(aiMessage)
            modelContext.saveOrLog("AI回答保存")

            remaining = response.remaining
            limit = response.limit
        } catch AIServiceError.rateLimitExceeded(let newLimit, _) {
            remaining = 0
            limit = newLimit
            showRateLimit = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            proxy.scrollTo(bottomID, anchor: .bottom)
        }
    }
}
