import Foundation
import Observation
import RosettaBBCore

@MainActor
@Observable
final class ScanViewModel {
    private(set) var entries: [AppEntry] = []
    private(set) var isScanning = false
    private(set) var updateStatuses: [URL: UpdateStatus] = [:]
    private(set) var isCheckingUpdates = false
    var showIntelOnly = true

    var visibleEntries: [AppEntry] {
        showIntelOnly ? entries.filter { $0.verdict == .intel } : entries
    }

    var intelCount: Int { entries.filter { $0.verdict == .intel }.count }
    var universalCount: Int { entries.filter { $0.verdict == .universal }.count }
    var appleCount: Int { entries.filter { $0.verdict == .appleSilicon }.count }

    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        entries = []
        updateStatuses = [:]
        let roots = AppScanner.defaultRoots
        entries = await Task.detached(priority: .userInitiated) {
            AppScanner().scan(roots: roots)
        }.value
        isScanning = false
    }

    /// Проверяет обновления для всех видимых Intel-приложений (сеть только тут).
    func checkUpdates() async {
        guard !isCheckingUpdates else { return }
        let targets = visibleEntries.filter { $0.verdict == .intel }
        guard !targets.isEmpty else { return }

        isCheckingUpdates = true
        for app in targets { updateStatuses[app.id] = .checking }

        let checker = UpdateChecker(providers: [
            AppStoreUpdateProvider(fetcher: URLSessionDataFetcher()),
            SparkleUpdateProvider(fetcher: URLSessionDataFetcher()),
            HomebrewUpdateProvider(runner: ProcessCommandRunner()),
        ])

        await withTaskGroup(of: (URL, UpdateStatus).self) { group in
            var iterator = targets.makeIterator()
            for _ in 0..<min(6, targets.count) {
                if let app = iterator.next() {
                    group.addTask { (app.id, await checker.check(app)) }
                }
            }
            while let (id, status) = await group.next() {
                updateStatuses[id] = status
                if let app = iterator.next() {
                    group.addTask { (app.id, await checker.check(app)) }
                }
            }
        }

        isCheckingUpdates = false
    }
}
