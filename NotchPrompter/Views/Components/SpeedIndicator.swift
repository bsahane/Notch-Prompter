import SwiftUI

struct SpeedIndicator: View {
    let speed: Double

    private var speedColor: Color {
        if speed >= 2.0 {
            return Color(nsColor: NSColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1))
        }
        if speed <= 0.5 {
            return Color(nsColor: NSColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1))
        }
        return Color.white.opacity(0.6)
    }

    var body: some View {
        Text(String(format: "%.1fx", speed))
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(speedColor)
    }
}
