import Foundation
import Testing
@testable import RosettaBBCore

/// Мок запуска команд с заранее заданным stdout или ошибкой.
struct StubRunner: CommandRunning {
    var output: String = ""
    var error: Error? = nil
    func run(_ executable: String, _ arguments: [String]) async throws -> String {
        if let error { throw error }
        return output
    }
}

@Suite("HomebrewUpdateProvider")
struct HomebrewUpdateProviderTests {
    private func app(named name: String) -> AppEntry {
        AppEntry(bundleURL: URL(fileURLWithPath: "/Applications/\(name).app"),
                 name: name, architectures: [.x86_64], verdict: .intel,
                 version: "100.0", bundleIdentifier: "com.example.\(name)")
    }

    private let outdatedJSON = """
    {"formulae":[],"casks":[{"name":"firefox","installed_versions":["100.0"],"current_version":"125.0"}]}
    """

    @Test("каск числится outdated и имя совпадает → success")
    func success() async throws {
        let provider = HomebrewUpdateProvider(
            runner: StubRunner(output: outdatedJSON),
            brewPath: "/opt/homebrew/bin/brew"
        )
        let outcome = await provider.check(app(named: "Firefox"))
        guard case let .success(result) = outcome else {
            Issue.record("ожидался .success, получено \(outcome)")
            return
        }
        #expect(result.latestVersion == "125.0")
        #expect(result.source == .homebrew)
    }

    @Test("brew недоступен (brewPath = nil) → notApplicable")
    func brewMissing() async throws {
        let provider = HomebrewUpdateProvider(runner: StubRunner(output: ""), brewPath: nil)
        let outcome = await provider.check(app(named: "Firefox"))
        guard case .notApplicable = outcome else {
            Issue.record("ожидался .notApplicable, получено \(outcome)")
            return
        }
    }

    @Test("имя не совпало ни с одним каском → notApplicable")
    func noMatch() async throws {
        let provider = HomebrewUpdateProvider(
            runner: StubRunner(output: outdatedJSON),
            brewPath: "/opt/homebrew/bin/brew"
        )
        let outcome = await provider.check(app(named: "SomethingElse"))
        guard case .notApplicable = outcome else {
            Issue.record("ожидался .notApplicable, получено \(outcome)")
            return
        }
    }
}
