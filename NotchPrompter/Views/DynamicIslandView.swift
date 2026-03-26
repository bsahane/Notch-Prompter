import SwiftUI

struct DynamicIslandView: View {
    @Bindable var state: PrompterState
    @State private var isMouseOver = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var notchInfo: (width: CGFloat, height: CGFloat, hasNotch: Bool) {
        AppDelegate.notchInfo()
    }

    private var collapsedWidth: CGFloat { notchInfo.width }
    private var collapsedHeight: CGFloat { notchInfo.height }

    private let expandedWidth: CGFloat = 500

    private var currentWidth: CGFloat {
        if state.isExpanded { return expandedWidth }
        return isMouseOver ? collapsedWidth + 20 : collapsedWidth
    }
    private var currentHeight: CGFloat {
        if state.isExpanded { return state.expandedHeight }
        return isMouseOver ? collapsedHeight + 4 : collapsedHeight
    }

    private var topCornerRadius: CGFloat {
        if state.isExpanded { return 19 }
        return 6
    }
    private var bottomCornerRadius: CGFloat {
        if state.isExpanded { return 24 }
        return isMouseOver ? 16 : 14
    }

    var body: some View {
        islandShape
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var islandShape: some View {
        ZStack(alignment: .top) {
            notchBackground
            content
        }
        .frame(width: currentWidth, height: currentHeight)
        .clipShape(NotchShape(topRadius: topCornerRadius, bottomRadius: bottomCornerRadius))
        .shadow(
            color: .black.opacity(state.isExpanded || isMouseOver ? (state.theme.usesGlass ? 0.15 : 0.25) : 0),
            radius: state.isExpanded ? 16 : 4,
            x: 0,
            y: state.isExpanded ? 2 : 1
        )
        .contentShape(NotchShape(topRadius: topCornerRadius, bottomRadius: bottomCornerRadius))
        .onTapGesture { state.toggleExpanded() }
        .contextMenu { contextMenuItems }
        .onHover { hovering in
            withAnimation(springAnimation) {
                isMouseOver = hovering
            }
        }
        .focusable()
        .animation(springAnimation, value: state.isExpanded)
        .animation(springAnimation, value: isMouseOver)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("NotchPrompter")
        .accessibilityHint(state.isExpanded ? "Double tap to collapse" : "Double tap to expand")
    }

    private var springAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .interactiveSpring(response: 0.38, dampingFraction: 0.8, blendDuration: 0)
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: { state.togglePlayPause() }) {
            Label(state.isPlaying ? "Pause" : "Play", systemImage: state.isPlaying ? "pause.fill" : "play.fill")
        }
        Button(action: { state.rewindToStart() }) {
            Label("Rewind", systemImage: "backward.end.fill")
        }
        Divider()
        Button(action: { state.openFile() }) {
            Label("Open File...", systemImage: "folder")
        }
        Button(action: { state.loadFromClipboard() }) {
            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
        }
        Divider()
        Button(action: { state.isMirrored.toggle() }) {
            Label(state.isMirrored ? "Disable Mirror" : "Mirror Text", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
        }
        Button(action: { state.showSettings.toggle() }) {
            Label("Settings", systemImage: "gearshape")
        }
        Divider()
        if state.hasScript {
            Text("\(state.wordCount) words \u{2022} \(state.estimatedReadingTime) read")
        }
    }

    // MARK: - Background

    private var notchBackground: some View {
        ZStack {
            if state.theme.usesGlass {
                Rectangle().fill(.ultraThinMaterial)
            } else {
                state.theme.background
                if state.isExpanded {
                    state.theme.expandedGradient
                }
            }
        }
        .opacity(state.isExpanded ? state.panelOpacity : 1.0)
    }

    // MARK: - Content

    private var content: some View {
        Group {
            if state.isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95)).animation(.smooth(duration: 0.35)))
            } else {
                collapsedContent
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Collapsed

    private var collapsedContent: some View {
        HStack(spacing: 0) {
            GreenDotIndicator()
                .padding(.leading, 14)

            if state.hasScript && !state.loadedFileName.isEmpty && isMouseOver {
                Text(state.loadedFileName)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .padding(.leading, 6)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            Spacer()

            if state.hasScript {
                HStack(spacing: 6) {
                    MiniProgressBar(progress: state.progress)
                    if state.isPlaying {
                        Image(systemName: "waveform")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                            .symbolEffect(.variableColor.iterative, isActive: state.isPlaying)
                    }
                }
                .padding(.trailing, 14)
            }
        }
    }

    // MARK: - Expanded

    private var expandedContent: some View {
        VStack(spacing: 0) {
            expandedHeader
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

            separatorLine

            ZStack {
                if state.hasScript {
                    ScrollingTextView(state: state)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .scaleEffect(x: state.isMirrored ? -1 : 1, y: 1)
                } else {
                    emptyState
                }

                if state.isHovered && state.wasPlayingBeforeHover {
                    pausedOverlay
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { hovering in
                state.handleHover(hovering)
            }

            separatorLine

            ControlsBarView(state: state)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

            resizeHandle
        }
    }

    private var resizeHandle: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 6)
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 3)
            Color.clear.frame(height: 6)
        }
        .frame(height: 15)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    state.adjustHeight(by: value.translation.height / 10)
                }
        )
        .onHover { hovering in
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var expandedHeader: some View {
        HStack(spacing: 8) {
            GreenDotIndicator()

            VStack(alignment: .leading, spacing: 1) {
                Text("NotchPrompter")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.gray)
                if !state.loadedFileName.isEmpty {
                    Text(state.loadedFileName)
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
            }

            formatBadge

            Spacer()

            if state.isHovered && state.wasPlayingBeforeHover {
                Image(systemName: "pause.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.gray)
                    .transition(.opacity)
            }

            mirrorButton
            opacityButton

            SpeedIndicator(speed: state.scrollSpeed)

            settingsButton
        }
    }

    private var settingsButton: some View {
        Button(action: { state.showSettings.toggle() }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 10))
                .foregroundStyle(state.showSettings ? Color.accentColor : .gray)
                .frame(width: 20, height: 20)
                .background(Color.white.opacity(state.showSettings ? 0.1 : 0.04), in: Circle())
        }
        .buttonStyle(.plain)
        .help("Settings")
        .accessibilityLabel("Settings")
        .popover(isPresented: Binding(
            get: { state.showSettings },
            set: { state.showSettings = $0 }
        ), arrowEdge: .bottom) {
            SettingsView(state: state)
                .preferredColorScheme(.dark)
        }
    }

    private var mirrorButton: some View {
        Button(action: { state.isMirrored.toggle() }) {
            Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill")
                .font(.system(size: 9))
                .foregroundStyle(state.isMirrored ? Color.accentColor : .gray)
                .frame(width: 20, height: 20)
                .background(Color.white.opacity(state.isMirrored ? 0.1 : 0.04), in: Circle())
        }
        .buttonStyle(.plain)
        .help("Mirror text")
    }

    private var opacityButton: some View {
        Button(action: {
            state.panelOpacity = state.panelOpacity > 0.5 ? 0.5 : 1.0
        }) {
            Image(systemName: state.panelOpacity < 1.0 ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 9))
                .foregroundStyle(state.panelOpacity < 1.0 ? .orange : .gray)
                .frame(width: 20, height: 20)
                .background(Color.white.opacity(state.panelOpacity < 1.0 ? 0.1 : 0.04), in: Circle())
        }
        .buttonStyle(.plain)
        .help("Toggle transparency")
    }

    private var formatBadge: some View {
        Button(action: {
            state.scriptFormat = state.scriptFormat == .markdown ? .plainText : .markdown
        }) {
            Text(state.scriptFormat == .markdown ? "MD" : "TXT")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(state.scriptFormat == .markdown ? Color.accentColor : .gray)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    (state.scriptFormat == .markdown ? Color.accentColor : Color.white)
                        .opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 4, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .help("Toggle Markdown rendering")
        .accessibilityLabel("Format: \(state.scriptFormat == .markdown ? "Markdown" : "Plain Text")")
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)
    }

    private var pausedOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 8))
                    Text("Paused")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.5))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08), in: Capsule())
                .padding(8)
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        .allowsHitTesting(false)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 48, height: 48)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.3))
            }

            Text("Paste your script (\u{2318}V)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))

            Text("or drag a text file here")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.3))

            Button(action: { state.openFile() }) {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                    Text("Open File")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
}
