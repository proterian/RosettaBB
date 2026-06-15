import Foundation

/// Проверяет обновления для приложений из Mac App Store через iTunes Lookup API.
public struct AppStoreUpdateProvider: UpdateProvider {
    private let fetcher: DataFetching

    public init(fetcher: DataFetching) {
        self.fetcher = fetcher
    }

    public func check(_ app: AppEntry) async -> ProviderOutcome {
        let receipt = app.bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("_MASReceipt")
            .appendingPathComponent("receipt")
        guard FileManager.default.fileExists(atPath: receipt.path),
              let bundleID = app.bundleIdentifier,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)") else {
            return .notApplicable
        }

        do {
            let data = try await fetcher.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]] else {
                return .failure(reason: "Не удалось разобрать ответ App Store")
            }
            guard let first = results.first, let version = first["version"] as? String else {
                return .failure(reason: "App Store вернул 0 результатов")
            }
            let trackURL = (first["trackViewUrl"] as? String).flatMap { URL(string: $0) }
            return .success(UpdateCheckResult(latestVersion: version, source: .appStore, url: trackURL))
        } catch {
            return .failure(reason: "Сеть: \(error.localizedDescription)")
        }
    }
}
