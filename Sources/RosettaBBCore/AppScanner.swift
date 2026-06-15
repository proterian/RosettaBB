import Foundation

/// Обходит заданные папки, находит .app и классифицирует каждое.
public struct AppScanner: Sendable {
    public init() {}

    /// Стандартные пути сканирования для MVP.
    public static var defaultRoots: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/Applications/Utilities", isDirectory: true),
            home.appendingPathComponent("Applications", isDirectory: true),
        ]
    }

    /// Сканирует все указанные корни и возвращает записи, отсортированные по имени.
    public func scan(roots: [URL]) -> [AppEntry] {
        let fm = FileManager.default
        var entries: [AppEntry] = []
        var seen: Set<URL> = []
        for root in roots {
            guard let items = try? fm.contentsOfDirectory(
                at: root, includingPropertiesForKeys: nil
            ) else { continue }
            for item in items where item.pathExtension == "app" {
                let std = item.standardizedFileURL
                guard seen.insert(std).inserted else { continue }
                entries.append(inspect(appBundle: std))
            }
        }
        return entries.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// Читает Info.plist бандла, определяет архитектуру главного бинарника.
    func inspect(appBundle: URL) -> AppEntry {
        let fallbackName = appBundle.deletingPathExtension().lastPathComponent
        let infoPlist = appBundle
            .appendingPathComponent("Contents")
            .appendingPathComponent("Info.plist")

        guard let dict = NSDictionary(contentsOf: infoPlist) else {
            return AppEntry(bundleURL: appBundle, name: fallbackName,
                            architectures: [], verdict: .unknown)
        }

        let version = dict["CFBundleShortVersionString"] as? String
        let bundleIdentifier = dict["CFBundleIdentifier"] as? String
        let name = (dict["CFBundleDisplayName"] as? String)
            ?? (dict["CFBundleName"] as? String)
            ?? fallbackName

        guard let exec = dict["CFBundleExecutable"] as? String else {
            return AppEntry(bundleURL: appBundle, name: name,
                            architectures: [], verdict: .unknown,
                            version: version, bundleIdentifier: bundleIdentifier)
        }

        let execURL = appBundle
            .appendingPathComponent("Contents")
            .appendingPathComponent("MacOS")
            .appendingPathComponent(exec)
        let archs = (try? MachOInspector.architectures(ofFileAt: execURL)) ?? []
        let verdict = AppClassifier.verdict(for: archs)
        return AppEntry(bundleURL: appBundle, name: name,
                        architectures: archs, verdict: verdict,
                        version: version, bundleIdentifier: bundleIdentifier)
    }
}
