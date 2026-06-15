import Foundation

/// Одно найденное приложение и его классификация.
/// Иконка в модель НЕ входит — грузится в UI по `bundleURL`.
public struct AppEntry: Identifiable, Sendable, Hashable {
    public let id: URL                       // путь к .app — он же идентификатор
    public let name: String
    public let architectures: Set<Architecture>
    public let verdict: Verdict
    public let version: String?              // CFBundleShortVersionString
    public let bundleIdentifier: String?     // CFBundleIdentifier

    public var bundleURL: URL { id }

    public init(
        bundleURL: URL,
        name: String,
        architectures: Set<Architecture>,
        verdict: Verdict,
        version: String? = nil,
        bundleIdentifier: String? = nil
    ) {
        self.id = bundleURL
        self.name = name
        self.architectures = architectures
        self.verdict = verdict
        self.version = version
        self.bundleIdentifier = bundleIdentifier
    }
}
