import SwiftUI

struct ControlsBarView: View {
    @Bindable var state: PrompterState

    var body: some View {
        HStack(spacing: 8) {
            headerNavButtons
            rewindButton
            playPauseButton
            speedControls

            Spacer()

            wordCountLabel
            elapsedTimeLabel
            countdownLabel
            progressSection
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Teleprompter controls")
    }

    private var headerNavButtons: some View {
        HStack(spacing: 2) {
            Button(action: { state.jumpToPreviousHeader() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .help("Previous header (\u{2190})")
            .accessibilityLabel("Previous header")

            Button(action: { state.jumpToNextHeader() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .help("Next header (\u{2192})")
            .accessibilityLabel("Next header")
        }
    }

    private var rewindButton: some View {
        Button(action: { state.rewindToStart() }) {
            Image(systemName: "backward.end.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.gray)
                .frame(width: 20, height: 20)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .help("Rewind to start")
        .accessibilityLabel("Rewind")
    }

    private var wordCountLabel: some View {
        Group {
            if state.hasScript {
                Text("\(state.wordCount)w")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.gray.opacity(0.5))
                    .help("\(state.wordCount) words \u{2022} \(state.estimatedReadingTime)")
            }
        }
    }

    private var elapsedTimeLabel: some View {
        Text(formatTime(state.elapsedTime))
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(.gray.opacity(0.7))
            .frame(width: 36, alignment: .trailing)
            .accessibilityLabel("Elapsed time: \(formatTime(state.elapsedTime))")
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var countdownLabel: some View {
        Group {
            if state.countdownMinutes > 0 {
                let remaining = state.countdownRemaining
                let isUrgent = remaining < 60 && remaining > 0
                let isOver = remaining <= 0 && state.elapsedTime > 0

                Text(isOver ? "OVER" : formatTime(remaining))
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isOver ? .red : (isUrgent ? .orange : .gray.opacity(0.5)))
                    .frame(width: isOver ? 30 : 36, alignment: .trailing)
                    .help("Countdown: \(Int(state.countdownMinutes)) min target")
            }
        }
    }

    private var playPauseButton: some View {
        Button(action: { state.togglePlayPause() }) {
            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(state.isPlaying ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
        .help(state.isPlaying ? "Pause (Space)" : "Play (Space)")
        .accessibilityLabel(state.isPlaying ? "Pause" : "Play")
    }

    private var speedControls: some View {
        HStack(spacing: 4) {
            Button(action: { state.decreaseSpeed() }) {
                Image(systemName: "minus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(width: 18, height: 18)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Decrease speed (\u{2193})")
            .accessibilityLabel("Decrease speed")

            SpeedIndicator(speed: state.scrollSpeed)
                .frame(width: 36)
                .accessibilityLabel("Speed: \(String(format: "%.1f", state.scrollSpeed))x")

            Button(action: { state.increaseSpeed() }) {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(width: 18, height: 18)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Increase speed (\u{2191})")
            .accessibilityLabel("Increase speed")
        }
    }

    private var progressSection: some View {
        HStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)

                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * max(0, min(state.progress, 1)), height: 4)
                }
                .frame(height: 4)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(width: 80, height: 20)

            Text("\(Int(state.progress * 100))%")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.gray)
                .frame(width: 32, alignment: .trailing)
        }
        .accessibilityLabel("Progress: \(Int(state.progress * 100)) percent")
    }
}
