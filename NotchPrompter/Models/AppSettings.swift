import Foundation

final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let defaultSpeed = "defaultSpeed"
        static let defaultFilePath = "defaultFilePath"
        static let defaultFontSize = "defaultFontSize"
        static let autoPlayOnOpen = "autoPlayOnOpen"
        static let expandedHeight = "expandedHeight"
        static let recentFiles = "recentFiles"
        static let scrollPositions = "scrollPositions"
        static let countdownMinutes = "countdownMinutes"
    }

    var defaultSpeed: Double {
        get { defaults.double(forKey: Keys.defaultSpeed).clamped(to: 0.25...3.0, fallback: 1.0) }
        set { defaults.set(newValue, forKey: Keys.defaultSpeed); defaults.synchronize() }
    }

    var defaultFilePath: String {
        get { defaults.string(forKey: Keys.defaultFilePath) ?? "" }
        set { defaults.set(newValue, forKey: Keys.defaultFilePath); defaults.synchronize() }
    }

    var defaultFontSize: Double {
        get { defaults.double(forKey: Keys.defaultFontSize).clamped(to: 16...48, fallback: 24) }
        set { defaults.set(newValue, forKey: Keys.defaultFontSize); defaults.synchronize() }
    }

    var autoPlayOnOpen: Bool {
        get { defaults.bool(forKey: Keys.autoPlayOnOpen) }
        set { defaults.set(newValue, forKey: Keys.autoPlayOnOpen); defaults.synchronize() }
    }

    var expandedHeight: Double {
        get { defaults.double(forKey: Keys.expandedHeight).clamped(to: 200...500, fallback: 280) }
        set { defaults.set(newValue, forKey: Keys.expandedHeight); defaults.synchronize() }
    }

    var countdownMinutes: Double {
        get { defaults.double(forKey: Keys.countdownMinutes) }
        set { defaults.set(newValue, forKey: Keys.countdownMinutes); defaults.synchronize() }
    }

    var recentFiles: [String] {
        get { defaults.stringArray(forKey: Keys.recentFiles) ?? [] }
        set {
            let trimmed = Array(newValue.prefix(5))
            defaults.set(trimmed, forKey: Keys.recentFiles)
            defaults.synchronize()
        }
    }

    func addRecentFile(_ path: String) {
        var files = recentFiles
        files.removeAll { $0 == path }
        files.insert(path, at: 0)
        recentFiles = files
    }

    func scrollPosition(for filePath: String) -> Double {
        let positions = defaults.dictionary(forKey: Keys.scrollPositions) as? [String: Double] ?? [:]
        return positions[filePath] ?? 0
    }

    func saveScrollPosition(_ offset: Double, for filePath: String) {
        var positions = defaults.dictionary(forKey: Keys.scrollPositions) as? [String: Double] ?? [:]
        positions[filePath] = offset
        defaults.set(positions, forKey: Keys.scrollPositions)
        defaults.synchronize()
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>, fallback: Double) -> Double {
        if self == 0 { return fallback }
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
