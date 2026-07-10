//
//  TimerImageStore.swift
//  MuscleApp
//
//  タイマー画面の中央に表示する画像をローカルに永続化する。
//  Documentsディレクトリに固定ファイル名で保存し、起動時に読み込む。
//  外部送信はしない（プライバシーポリシー準拠）。
//

import UIKit

final class TimerImageStore {
    static let shared = TimerImageStore()
    private init() {}

    private let filename = "buffito_timer_center.jpg"
    private let compressionQuality: CGFloat = 0.85

    private var fileURL: URL? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docs.appendingPathComponent(filename)
    }

    // 画像を保存（既存があれば上書き）
    @discardableResult
    func save(image: UIImage) -> Bool {
        guard let url = fileURL,
              let data = image.jpegData(compressionQuality: compressionQuality) else {
            return false
        }
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            AppLog.media.error("タイマー画像の保存失敗: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    // 保存済みの画像を読み込む（なければnil）
    func load() -> UIImage? {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            return UIImage(data: try Data(contentsOf: url))
        } catch {
            AppLog.media.error("タイマー画像の読み込み失敗: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    // 保存済み画像を削除（ファイルが無ければ何もしない）
    func delete() {
        guard let url = fileURL,
              FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            AppLog.media.error("タイマー画像の削除失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    // 画像が保存されているか
    var hasImage: Bool {
        guard let url = fileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
