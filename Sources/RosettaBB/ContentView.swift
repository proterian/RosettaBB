import SwiftUI
import AppKit
import RosettaBBCore

struct ContentView: View {
    @State private var model = ScanViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
    }

    private var toolbar: some View {
        HStack {
            Button {
                Task { await model.scan() }
            } label: {
                Label("Сканировать", systemImage: "magnifyingglass")
            }
            .disabled(model.isScanning)

            Button {
                Task { await model.checkUpdates() }
            } label: {
                Label("Проверить обновления", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(model.isScanning || model.isCheckingUpdates || model.intelCount == 0)

            Toggle("Только Intel", isOn: $model.showIntelOnly)
                .toggleStyle(.checkbox)

            Spacer()

            if model.isScanning || model.isCheckingUpdates {
                ProgressView().controlSize(.small)
            } else if !model.entries.isEmpty {
                Text("Intel: \(model.intelCount)  ·  Universal: \(model.universalCount)  ·  Apple: \(model.appleCount)")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        if model.isScanning {
            list
        } else if model.entries.isEmpty {
            VStack(spacing: 18) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 104, height: 104)
                }
                VStack(spacing: 6) {
                    Text("Нажмите «Сканировать»")
                        .font(.title3.weight(.semibold))
                    Text("Найдём приложения и покажем, какие из них Intel-only.")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.visibleEntries.isEmpty {
            ContentUnavailableView(
                "Intel-приложений не найдено",
                systemImage: "checkmark.seal",
                description: Text("Все найденные приложения — Universal или Apple Silicon.")
            )
            .frame(maxHeight: .infinity)
        } else {
            list
        }
    }

    private var list: some View {
        List(model.visibleEntries) { entry in
            AppRow(entry: entry, status: model.updateStatuses[entry.id] ?? .notChecked)
        }
    }
}

private struct AppRow: View {
    let entry: AppEntry
    let status: UpdateStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: entry.bundleURL.path))
                .resizable()
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name).font(.body)
                Text(entry.bundleURL.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
            updateView
            badge
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([entry.bundleURL])
            } label: {
                Image(systemName: "arrow.right.circle")
            }
            .buttonStyle(.borderless)
            .help("Показать в Finder")
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var updateView: some View {
        switch status {
        case .notChecked:
            EmptyView()
        case .checking:
            ProgressView().controlSize(.small)
        case .updateAvailable(let version, let source, let url):
            if let url {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Text("↑ \(version) · \(sourceLabel(source))")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.green)
                .help("Открыть страницу обновления")
            } else {
                Text("↑ \(version) · \(sourceLabel(source))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        case .upToDate(let source):
            Text("актуально · \(sourceLabel(source))")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .unknownSource:
            Text("источник неизвестен")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .failed(let reason):
            Text("ошибка")
                .font(.caption)
                .foregroundStyle(.red)
                .help(reason)
        }
    }

    private func sourceLabel(_ source: UpdateSource) -> String {
        switch source {
        case .appStore: return "App Store"
        case .sparkle:  return "Sparkle"
        case .homebrew: return "Homebrew"
        }
    }

    private var badge: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch entry.verdict {
        case .intel:        return "Intel"
        case .universal:    return "Universal"
        case .appleSilicon: return "Apple"
        case .unknown:      return "—"
        }
    }

    private var color: Color {
        switch entry.verdict {
        case .intel:        return .orange
        case .universal:    return .blue
        case .appleSilicon: return .green
        case .unknown:      return .gray
        }
    }
}
