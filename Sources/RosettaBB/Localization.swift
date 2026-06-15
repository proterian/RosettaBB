import Foundation

/// Локализованная строка из бандла модуля.
/// Строки лежат в Resources/<lang>.lproj/Localizable.strings, а не в main-бандле,
/// поэтому SwiftUI не находит их автоматически — берём явно из `.module`.
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}
