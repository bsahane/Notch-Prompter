import SwiftUI

enum PrompterTheme: String, CaseIterable, Identifiable {
    case notchDark
    case glass
    case midnight
    case terminal
    case warm
    case highContrast

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notchDark: return "Notch Dark"
        case .glass: return "Glass"
        case .midnight: return "Midnight"
        case .terminal: return "Terminal"
        case .warm: return "Warm"
        case .highContrast: return "High Contrast"
        }
    }

    var iconName: String {
        switch self {
        case .notchDark: return "moon.fill"
        case .glass: return "rectangle.on.rectangle"
        case .midnight: return "sparkles"
        case .terminal: return "terminal.fill"
        case .warm: return "sun.max.fill"
        case .highContrast: return "circle.lefthalf.filled"
        }
    }

    var textColor: Color {
        switch self {
        case .notchDark, .midnight: return .white.opacity(0.92)
        case .glass: return .white.opacity(0.95)
        case .terminal: return Color(red: 0.2, green: 1.0, blue: 0.4)
        case .warm: return Color(red: 1.0, green: 0.95, blue: 0.85)
        case .highContrast: return .white
        }
    }

    var headerColor: Color {
        switch self {
        case .terminal: return Color(red: 0.3, green: 1.0, blue: 0.5)
        case .warm: return Color(red: 1.0, green: 0.8, blue: 0.5)
        default: return textColor
        }
    }

    var usesGlass: Bool { self == .glass }

    @ViewBuilder
    var background: some View {
        switch self {
        case .notchDark:
            Color.black
        case .glass:
            Color.clear
        case .midnight:
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.06, blue: 0.18), Color(red: 0.02, green: 0.02, blue: 0.08)],
                startPoint: .top, endPoint: .bottom
            )
        case .terminal:
            Color(red: 0.02, green: 0.06, blue: 0.02)
        case .warm:
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.08, blue: 0.04), Color(red: 0.06, green: 0.04, blue: 0.02)],
                startPoint: .top, endPoint: .bottom
            )
        case .highContrast:
            Color.black
        }
    }

    @ViewBuilder
    var expandedGradient: some View {
        switch self {
        case .notchDark:
            LinearGradient(colors: [Color(white: 0.08), .black], startPoint: .top, endPoint: .bottom)
        case .glass:
            Color.clear
        case .midnight:
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.08, blue: 0.22), Color(red: 0.03, green: 0.02, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            )
        case .terminal:
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.08, blue: 0.03), Color(red: 0.01, green: 0.04, blue: 0.01)],
                startPoint: .top, endPoint: .bottom
            )
        case .warm:
            LinearGradient(
                colors: [Color(red: 0.14, green: 0.1, blue: 0.06), Color(red: 0.06, green: 0.04, blue: 0.02)],
                startPoint: .top, endPoint: .bottom
            )
        case .highContrast:
            Color.black
        }
    }

    var previewColors: [Color] {
        switch self {
        case .notchDark: return [.black, Color(white: 0.08)]
        case .glass: return [Color(white: 0.3).opacity(0.5), Color(white: 0.2).opacity(0.3)]
        case .midnight: return [Color(red: 0.08, green: 0.06, blue: 0.18), Color(red: 0.02, green: 0.02, blue: 0.08)]
        case .terminal: return [Color(red: 0.02, green: 0.06, blue: 0.02), Color(red: 0.01, green: 0.04, blue: 0.01)]
        case .warm: return [Color(red: 0.12, green: 0.08, blue: 0.04), Color(red: 0.06, green: 0.04, blue: 0.02)]
        case .highContrast: return [.black, .black]
        }
    }
}
