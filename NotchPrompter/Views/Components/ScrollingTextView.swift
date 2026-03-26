import SwiftUI
import Combine

struct ScrollingTextView: View {
    @Bindable var state: PrompterState
    private let scrollPixelsPerSecond: CGFloat = 40
    private let frameRate: TimeInterval = 1.0 / 60.0

    private var fadeColor: Color {
        state.theme.usesGlass ? Color(white: 0.15) : (state.theme == .midnight ? Color(red: 0.03, green: 0.02, blue: 0.1) : (state.theme == .terminal ? Color(red: 0.01, green: 0.04, blue: 0.01) : (state.theme == .warm ? Color(red: 0.06, green: 0.04, blue: 0.02) : .black)))
    }

    var body: some View {
        GeometryReader { geo in
            let visibleHeight = geo.size.height

            ZStack(alignment: .top) {
                textContent
                    .frame(width: geo.size.width, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -state.scrollOffset)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear
                                .onAppear {
                                    state.totalTextHeight = textGeo.size.height
                                    state.visibleAreaHeight = visibleHeight
                                }
                                .onChange(of: state.scrollOffset) {
                                    let textHeight = textGeo.size.height
                                    let maxScroll = max(textHeight - visibleHeight, 0)
                                    if maxScroll > 0 {
                                        state.progress = min(state.scrollOffset / maxScroll, 1.0)
                                    }
                                    if state.scrollOffset >= maxScroll && maxScroll > 0 {
                                        state.isPlaying = false
                                        state.progress = 1.0
                                    }
                                }
                        }
                    )

                topFade(height: 20)
                    .frame(maxHeight: .infinity, alignment: .top)

                if state.showFocusLine && state.isPlaying {
                    focusLine
                        .frame(maxHeight: .infinity, alignment: .top)
                        .offset(y: visibleHeight * 0.25)
                }

                bottomFade(height: 20)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .clipped()
        .onReceive(
            Timer.publish(every: frameRate, on: .main, in: .common).autoconnect()
        ) { _ in
            guard state.isPlaying else { return }
            let increment = scrollPixelsPerSecond * state.scrollSpeed * frameRate
            state.scrollOffset += increment
            state.elapsedTime += frameRate
        }
    }

    @ViewBuilder
    private var textContent: some View {
        if state.scriptFormat == .markdown {
            MarkdownTextView(text: state.scriptText, fontSize: state.fontSize) { positions in
                state.headerOffsets = positions.map(\.offset)
            }
            .textSelection(.enabled)
        } else {
            Text(state.scriptText)
                .font(.system(size: state.fontSize))
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(6)
                .tracking(0.2)
                .textSelection(.enabled)
        }
    }

    private func topFade(height: CGFloat) -> some View {
        LinearGradient(
            colors: [fadeColor, .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }

    private var focusLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, .blue.opacity(0.15), .blue.opacity(0.3), .blue.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 28)
            .allowsHitTesting(false)
    }

    private func bottomFade(height: CGFloat) -> some View {
        LinearGradient(
            colors: [.clear, fadeColor],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
    }
}
