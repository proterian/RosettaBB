import Foundation
import Testing
@testable import RosettaBBCore

@Suite("AppScanner")
struct AppScannerTests {
    /// Создаёт фейковый .app с заданными байтами исполняемого файла.
    private func makeApp(
        named name: String,
        in root: URL,
        execBytes: [UInt8],
        version: String = "1.0",
        bundleID: String? = nil
    ) throws {
        let macOS = root
            .appendingPathComponent("\(name).app")
            .appendingPathComponent("Contents")
            .appendingPathComponent("MacOS")
        try FileManager.default.createDirectory(at: macOS, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleExecutable": name,
            "CFBundleName": name,
            "CFBundleShortVersionString": version,
            "CFBundleIdentifier": bundleID ?? "com.test.\(name)",
        ]
        let plistURL = root
            .appendingPathComponent("\(name).app")
            .appendingPathComponent("Contents")
            .appendingPathComponent("Info.plist")
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: plistURL)
        try Data(execBytes).write(to: macOS.appendingPathComponent(name))
    }

    @Test("сканирует фейковые бандлы и классифицирует их")
    func scansAndClassifies() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("rbb-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try makeApp(named: "IntelApp", in: root,
                    execBytes: [0xCF, 0xFA, 0xED, 0xFE, 0x07, 0x00, 0x00, 0x01])
        try makeApp(named: "ArmApp", in: root,
                    execBytes: [0xCF, 0xFA, 0xED, 0xFE, 0x0C, 0x00, 0x00, 0x01])

        let entries = AppScanner().scan(roots: [root])

        #expect(entries.count == 2)
        let intel = try #require(entries.first { $0.name == "IntelApp" })
        let arm = try #require(entries.first { $0.name == "ArmApp" })
        #expect(intel.verdict == .intel)
        #expect(arm.verdict == .appleSilicon)
    }

    @Test("дефолтные пути включают /Applications")
    func defaultRoots() {
        let paths = AppScanner.defaultRoots.map(\.path)
        #expect(paths.contains("/Applications"))
    }

    @Test("читает version и bundleIdentifier из Info.plist")
    func readsVersionAndBundleID() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("rbb-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try makeApp(named: "Versioned", in: root,
                    execBytes: [0xCF, 0xFA, 0xED, 0xFE, 0x0C, 0x00, 0x00, 0x01],
                    version: "3.2.1", bundleID: "com.example.versioned")

        let app = try #require(AppScanner().scan(roots: [root]).first)
        #expect(app.version == "3.2.1")
        #expect(app.bundleIdentifier == "com.example.versioned")
    }
}
