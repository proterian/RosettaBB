import Foundation
import Testing
@testable import RosettaBBCore

@Suite("SparkleUpdateProvider")
struct SparkleUpdateProviderTests {
    /// Создаёт бандл с Info.plist, содержащим SUFeedURL.
    private func makeSparkleBundle(feed: String?) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("rbb-spk-\(UUID().uuidString)")
        let contents = root.appendingPathComponent("Spk.app").appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        var plist: [String: Any] = ["CFBundleName": "Spk"]
        if let feed { plist["SUFeedURL"] = feed }
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
        return root.appendingPathComponent("Spk.app")
    }

    private let appcast = """
    <?xml version="1.0" encoding="utf-8"?>
    <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
      <channel>
        <item>
          <enclosure url="https://example.com/App-1.5.zip" sparkle:shortVersionString="1.5" sparkle:version="150"/>
        </item>
        <item>
          <enclosure url="https://example.com/App-2.0.zip" sparkle:shortVersionString="2.0" sparkle:version="200"/>
        </item>
      </channel>
    </rss>
    """

    @Test("есть SUFeedURL → выбирает максимальную версию и URL")
    func picksLatest() async throws {
        let bundle = try makeSparkleBundle(feed: "https://example.com/appcast.xml")
        defer { try? FileManager.default.removeItem(at: bundle.deletingLastPathComponent()) }
        let app = AppEntry(bundleURL: bundle, name: "Spk",
                           architectures: [.x86_64], verdict: .intel,
                           version: "1.0", bundleIdentifier: "com.example.spk")
        let provider = SparkleUpdateProvider(fetcher: StubFetcher(data: Data(appcast.utf8)))

        let outcome = await provider.check(app)
        guard case let .success(result) = outcome else {
            Issue.record("ожидался .success, получено \(outcome)")
            return
        }
        #expect(result.latestVersion == "2.0")
        #expect(result.source == .sparkle)
        #expect(result.url?.absoluteString == "https://example.com/App-2.0.zip")
    }

    @Test("child-element форма sparkle:shortVersionString")
    func childElementForm() async throws {
        let bundle = try makeSparkleBundle(feed: "https://example.com/appcast.xml")
        defer { try? FileManager.default.removeItem(at: bundle.deletingLastPathComponent()) }
        let app = AppEntry(bundleURL: bundle, name: "Spk",
                           architectures: [.x86_64], verdict: .intel,
                           version: "1.0", bundleIdentifier: "com.example.spk")
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
          <channel>
            <item>
              <sparkle:shortVersionString>3.1</sparkle:shortVersionString>
              <enclosure url="https://example.com/App-3.1.zip"/>
            </item>
          </channel>
        </rss>
        """
        let provider = SparkleUpdateProvider(fetcher: StubFetcher(data: Data(xml.utf8)))
        let outcome = await provider.check(app)
        guard case let .success(result) = outcome else {
            Issue.record("ожидался .success, получено \(outcome)")
            return
        }
        #expect(result.latestVersion == "3.1")
        #expect(result.url?.absoluteString == "https://example.com/App-3.1.zip")
    }

    @Test("нет SUFeedURL → notApplicable")
    func notApplicable() async throws {
        let bundle = try makeSparkleBundle(feed: nil)
        defer { try? FileManager.default.removeItem(at: bundle.deletingLastPathComponent()) }
        let app = AppEntry(bundleURL: bundle, name: "Spk",
                           architectures: [.x86_64], verdict: .intel,
                           version: "1.0", bundleIdentifier: "com.example.spk")
        let provider = SparkleUpdateProvider(fetcher: StubFetcher(data: Data()))

        let outcome = await provider.check(app)
        guard case .notApplicable = outcome else {
            Issue.record("ожидался .notApplicable, получено \(outcome)")
            return
        }
    }
}
