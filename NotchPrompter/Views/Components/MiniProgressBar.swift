import SwiftUI

struct MiniProgressBar: View {
    let progress: Double

    private let accentBlue = Color(nsColor: NSColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1))

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 3)

                Capsule()
                    .fill(accentBlue)
                    .frame(width: geo.size.width * max(0, min(progress, 1)), height: 3)
            }
        }
        .frame(width: 44, height: 3)
    }
}
