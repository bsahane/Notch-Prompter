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

            elapsedTimeLabel
            progressSection
        }
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

            Button(action: { state.jumpToNextHeader() }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
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
    }

    private var elapsedTimeLabel: some View {
        Text(formatTime(state.elapsedTime))
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundStyle(.gray.opacity(0.7))
            .frame(width: 36, alignment: .trailing)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var playPauseButton: some View {
        Button(action: { state.togglePlayPause() }) {
            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.1), in: Circle())
        }
        .buttonStyle(.plain)
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

            SpeedIndicator(speed: state.scrollSpeed)
                .frame(width: 36)

            Button(action: { state.increaseSpeed() }) {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.gray)
                    .frame(width: 18, height: 18)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
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
                        .fill(.white)
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
    }
}
