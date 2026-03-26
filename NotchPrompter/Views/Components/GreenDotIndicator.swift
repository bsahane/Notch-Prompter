import SwiftUI

struct GreenDotIndicator: View {
    @State private var isPulsing = false

    private let activeGreen = Color(nsColor: NSColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1))

    var body: some View {
        ZStack {
            Circle()
                .fill(activeGreen.opacity(0.3))
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.3 : 1.0)

            Circle()
                .fill(activeGreen)
                .frame(width: 8, height: 8)
        }
        .opacity(isPulsing ? 1.0 : 0.8)
        .animation(
            .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear { isPulsing = true }
    }
}
