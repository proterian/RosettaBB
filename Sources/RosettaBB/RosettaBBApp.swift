import SwiftUI
import AppKit

@main
struct RosettaBBApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("RosettaBB") {
            ContentView()
                .frame(minWidth: 640, minHeight: 480)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(L("about_menu")) {
                    RosettaBBApp.showAboutPanel()
                }
            }
        }
    }

    /// Стандартная панель «О программе» с описанием, версией и ссылкой.
    @MainActor
    private static func showAboutPanel() {
        let credits = NSAttributedString(
            string: L("about_credits"),
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: credits,
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2026 proterian · MIT",
        ])
    }
}

/// Без `.app`-бандла запуск через `swift run` стартует как accessory-процесс:
/// окно не выходит вперёд и нет иконки в Dock. Делегат выставляет обычную
/// activation policy и активирует приложение.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
