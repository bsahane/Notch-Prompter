import SwiftUI

struct SpeedIndicator: View {
    let speed: Double

    private var speedColor: Color {
        if speed >= 2.0 { return .orange }
        if speed <= 0.5 { return Color.accentColor }
        return Color.white.opacity(0.6)
    }

    var body: some View {
        Text(String(format: "%.1fx", speed))
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(speedColor)
    }
}
