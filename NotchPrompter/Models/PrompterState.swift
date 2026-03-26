import SwiftUI
import Combine
import UniformTypeIdentifiers

enum ScriptFormat: String {
    case plainText
    case markdown
    case richText
}

@Observable
final class PrompterState {
    var isExpanded = false
    var isPlaying = false
    var isHovered = false
    var wasPlayingBeforeHover = false
    var showSettings = false
    var scrollSpeed: Double = AppSettings.shared.defaultSpeed
    var scrollOffset: CGFloat = 0
    var scriptText: String = ""
    var scriptFormat: ScriptFormat = .markdown
    var fontSize: CGFloat = CGFloat(AppSettings.shared.defaultFontSize)
    var progress: Double = 0
    var expandedHeight: CGFloat = CGFloat(AppSettings.shared.expandedHeight)
    var elapsedTime: TimeInterval = 0
    var isMirrored = false
    var panelOpacity: Double = 1.0
    var showFocusLine = true
    var loadedFileName: String = ""

    init() {
        let filePath = AppSettings.shared.defaultFilePath
        if !filePath.isEmpty, FileManager.default.fileExists(atPath: filePath) {
            let url = URL(fileURLWithPath: filePath)
            if let text = try? String(contentsOf: url, encoding: .utf8),
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                scriptText = text
                loadedFileName = url.lastPathComponent
                let ext = url.pathExtension.lowercased()
                scriptFormat = (ext == "md" || ext == "markdown") ? .markdown : detectFormat(text: text)
                return
            }
        }
        scriptText = PrompterState.sampleScript
        loadedFileName = "Sample Script"
    }

    static let sampleScript = """
    # Welcome to NotchPrompter

    Your **teleprompter** that lives right under the *notch*.

    ## Getting Started

    Press **Space** to start scrolling. Use **Up/Down** arrows to adjust speed.

    ### Loading Your Script

    - **Cmd+V** — Paste from clipboard
    - **Drag & Drop** — Drop `.txt`, `.md`, or `.rtf` files
    - Supports **Markdown**, plain text, and rich text formats

    ### Tips for Presenting

    1. Keep sentences *short and punchy*
    2. Use larger font sizes for faster reading
    3. Set a comfortable scroll speed before your call
    4. Text stays near the camera for natural **eye contact**

    > Pro tip: Hover over the panel to auto-pause scrolling.

    Press **Space** now to try it. **Escape** to collapse.
    """

    var hasScript: Bool { !scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var wordCount: Int {
        scriptText.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    var estimatedReadingTime: String {
        let minutes = max(1, wordCount / 200)
        return minutes == 1 ? "~1 min" : "~\(minutes) min"
    }

    var renderedText: AttributedString {
        if scriptFormat == .markdown {
            do {
                var result = try AttributedString(
                    markdown: scriptText,
                    options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                )
                result.foregroundColor = .white.opacity(0.92)
                result.font = .system(size: fontSize)
                return result
            } catch {
                return plainAttributedString
            }
        }
        return plainAttributedString
    }

    private var plainAttributedString: AttributedString {
        var result = AttributedString(scriptText)
        result.foregroundColor = .white.opacity(0.92)
        result.font = .system(size: fontSize)
        return result
    }

    static let supportedFileExtensions = ["txt", "md", "markdown", "rtf", "text", "strings"]

    static let minSpeed: Double = 0.25
    static let maxSpeed: Double = 3.0
    static let speedStep: Double = 0.25
    static let minFontSize: CGFloat = 16
    static let maxFontSize: CGFloat = 48
    static let defaultFontSize: CGFloat = 24
    static let minExpandedHeight: CGFloat = 200
    static let maxExpandedHeight: CGFloat = 500

    func increaseSpeed() {
        scrollSpeed = min(scrollSpeed + Self.speedStep, Self.maxSpeed)
    }

    func decreaseSpeed() {
        scrollSpeed = max(scrollSpeed - Self.speedStep, Self.minSpeed)
    }

    func increaseFontSize() {
        fontSize = min(fontSize + 2, Self.maxFontSize)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 2, Self.minFontSize)
    }

    func resetFontSize() {
        fontSize = Self.defaultFontSize
    }

    var headerOffsets: [CGFloat] = []
    var totalTextHeight: CGFloat = 0
    var visibleAreaHeight: CGFloat = 0

    func adjustHeight(by delta: CGFloat) {
        expandedHeight = min(max(expandedHeight + delta, Self.minExpandedHeight), Self.maxExpandedHeight)
        AppSettings.shared.expandedHeight = Double(expandedHeight)
    }

    func manualScroll(by delta: CGFloat) {
        let newOffset = scrollOffset - delta
        scrollOffset = max(0, newOffset)
    }

    func jumpToNextHeader() {
        let currentPos = scrollOffset
        for offset in headerOffsets.sorted() {
            if offset > currentPos + 5 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollOffset = offset
                }
                return
            }
        }
    }

    func jumpToPreviousHeader() {
        let currentPos = scrollOffset
        for offset in headerOffsets.sorted().reversed() {
            if offset < currentPos - 5 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollOffset = offset
                }
                return
            }
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollOffset = 0
        }
    }

    func rewindToStart() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollOffset = 0
            progress = 0
            elapsedTime = 0
        }
    }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText, .text, .rtf, .data]
        panel.allowsOtherFileTypes = true
        panel.title = "Open Script File"
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 5)
        if panel.runModal() == .OK, let url = panel.url {
            loadFromFile(url: url)
        }
    }

    func togglePlayPause() {
        isPlaying.toggle()
        wasPlayingBeforeHover = false
        haptic(.generic)
    }

    func handleHover(_ hovering: Bool) {
        isHovered = hovering
        if hovering && isPlaying {
            wasPlayingBeforeHover = true
            isPlaying = false
        } else if !hovering && wasPlayingBeforeHover {
            isPlaying = true
            wasPlayingBeforeHover = false
        }
    }

    func toggleExpanded() {
        haptic(.levelChange)
        withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.8, blendDuration: 0)) {
            isExpanded.toggle()
            if isExpanded {
                if AppSettings.shared.autoPlayOnOpen && hasScript {
                    isPlaying = true
                }
            } else {
                isPlaying = false
                elapsedTime = 0
            }
        }
    }

    func resetScroll() {
        scrollOffset = 0
        progress = 0
        isPlaying = false
    }

    func loadFromClipboard() {
        guard let string = NSPasteboard.general.string(forType: .string),
              !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        scriptText = string
        scriptFormat = detectFormat(text: string)
        resetScroll()
    }

    func loadFromFile(url: URL) {
        let ext = url.pathExtension.lowercased()

        if ext == "rtf" {
            if let rtfData = try? Data(contentsOf: url),
               let attributed = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                scriptText = attributed.string
                scriptFormat = .plainText
                loadedFileName = url.lastPathComponent
                resetScroll()
                return
            }
        }

        guard let text = try? String(contentsOf: url, encoding: .utf8),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        scriptText = text
        scriptFormat = (ext == "md" || ext == "markdown") ? .markdown : detectFormat(text: text)
        loadedFileName = url.lastPathComponent
        resetScroll()
    }

    private func detectFormat(text: String) -> ScriptFormat {
        let mdPatterns = ["# ", "## ", "**", "__", "- ", "1. ", "> ", "```", "[", "!["]
        let matchCount = mdPatterns.filter { text.contains($0) }.count
        return matchCount >= 2 ? .markdown : .plainText
    }

    func haptic(_ pattern: NSHapticFeedbackManager.FeedbackPattern) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
    }
}
