//
//  ContactFormView.swift
//  MuscleApp
//
//  お問い合わせフォーム。件名と内容を入力 → メールアプリで送信。
//  送信先メールアドレスはコード内で保持し、UIには表示しない。
//

import SwiftUI
import MessageUI
import UIKit

struct ContactFormView: View {
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var showMailComposer: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    // 送信先メールアドレス（UIには表示しない）
    private let recipientEmail = "buffito.app@gmail.com"

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("ご質問・ご意見・不具合報告など、お気軽にお送りください。送信ボタンを押すとメールアプリが開きます。")
                        .font(.subheadline)
                        .foregroundColor(.appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    inputSection(title: "件名") {
                        TextField("", text: $subject, prompt: Text("例：機能のご要望").foregroundColor(.gray))
                            .foregroundColor(.appTextPrimary)
                            .padding()
                            .background(Color.appCard)
                            .cornerRadius(10)
                    }

                    inputSection(title: "内容") {
                        TextEditor(text: $message)
                            .foregroundColor(.appTextPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color.appCard)
                            .cornerRadius(10)
                            .frame(minHeight: 200)
                    }

                    Button {
                        handleSend()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                            Text("送信")
                                .font(.headline)
                        }
                        .foregroundColor(canSubmit ? Color(.systemBackground) : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canSubmit ? Color.appTextPrimary : Color.appField)
                        .cornerRadius(12)
                    }
                    .disabled(!canSubmit)
                }
                .padding()
            }
        }
        .navigationTitle("お問い合わせ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showMailComposer) {
            MailComposer(
                recipients: [recipientEmail],
                subject: subject,
                body: message
            )
        }
        .alert("送信できません", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    // 件名・内容のどちらも空白でなければ送信可能
    private var canSubmit: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // 送信処理：標準メーラー → 失敗時は mailto: フォールバック
    private func handleSend() {
        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
            return
        }

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(recipientEmail)?subject=\(encodedSubject)&body=\(encodedBody)"

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            alertMessage = "メールアプリが設定されていないため送信できません。お手数ですが、メールアプリの設定をご確認ください。"
            showAlert = true
        }
    }

    // タイトル付きの入力フィールド
    private func inputSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            content()
        }
    }
}

// MFMailComposeViewController の SwiftUI ラッパー
struct MailComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            dismiss()
        }
    }
}
