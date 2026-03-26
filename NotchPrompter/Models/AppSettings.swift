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
}

private extension Double {
    func clamped(to range: ClosedRange<Double>, fallback: Double) -> Double {
        if self == 0 { return fallback }
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
