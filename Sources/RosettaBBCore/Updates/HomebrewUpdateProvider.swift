import Foundation

/// Best-effort проверка обновлений через Homebrew Cask.
/// Сопоставление .app ↔ cask эвристическое (по имени).
public struct HomebrewUpdateProvider: UpdateProvider {
    private let runner: CommandRunning
    private let brewPath: String?

    public init(runner: CommandRunning, brewPath: String? = HomebrewUpdateProvider.defaultBrewPath()) {
        self.runner = runner
        self.brewPath = brewPath
    }

    /// Ищет brew в стандартных путях (arm64, затем Intel).
    public static func defaultBrewPath() -> String? {
        for path in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"] {
            if FileManager.default.isExecutableFile(atPath: path) { return path }
        }
        return nil
    }

    public func check(_ app: AppEntry) async -> ProviderOutcome {
        guard let brewPath else { return .notApplicable }

        do {
            let output = try await runner.run(brewPath, ["outdated", "--cask", "--greedy", "--json=v2"])
            guard let data = output.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let casks = json["casks"] as? [[String: Any]] else {
                return .failure(reason: "Не удалось разобрать вывод brew")
            }

            let target = app.name.lowercased()
            for cask in casks {
                guard let name = (cask["name"] as? String)?.lowercased(),
                      let current = cask["current_version"] as? String else { continue }
                if name == target || target.contains(name) || name.contains(target) {
                    return .success(UpdateCheckResult(latestVersion: current, source: .homebrew, url: nil))
                }
            }
            return .notApplicable
        } catch {
            return .failure(reason: "brew: \(error.localizedDescription)")
        }
    }
}
