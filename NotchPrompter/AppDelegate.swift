import AppKit
import SwiftUI

final class DragDropHostingView<Content: View>: NSHostingView<Content> {
    var onTextDropped: ((String) -> Void)?
    var onFileDropped: ((URL) -> Void)?
    weak var prompterState: PrompterState?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func enableDragAndDrop() {
        registerForDraggedTypes([.string, .fileURL])
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard contentRect().contains(point) else { return nil }
        return super.hitTest(point)
    }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        let point = convert(sender.draggingLocation, from: nil)
        guard contentRect().contains(point) else { return [] }
        return .copy
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            for url in urls {
                let ext = url.pathExtension.lowercased()
                if PrompterState.supportedFileExtensions.contains(ext) {
                    onFileDropped?(url)
                    return true
                }
            }
        }

        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onTextDropped?(text)
            return true
        }

        return false
    }

    private func contentRect() -> NSRect {
        let isExpanded = prompterState?.isExpanded ?? false
        let notch = AppDelegate.notchInfo()
        let viewW = bounds.width
        let viewH = bounds.height

        let contentW: CGFloat
        let contentH: CGFloat

        if isExpanded {
            contentW = min(viewW, 500)
            contentH = (prompterState?.expandedHeight ?? 280) + 40
        } else {
            contentW = notch.width + 30
            contentH = notch.height + 10
        }

        let x = (viewW - contentW) / 2
        let y = viewH - contentH
        return NSRect(x: x, y: y, width: contentW, height: contentH)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel?
    private let prompterState = PrompterState()
    private var keyMonitor: Any?
    private var statusItem: NSStatusItem?

    static let panelWidth: CGFloat = 500
    static let panelHeight: CGFloat = 500

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupMainMenu()
        setupStatusBarItem()
        setupPanel()
        setupKeyboardMonitor()
        observeExpansionState()
        setupMousePassthrough()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Menu Bar

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit NotchPrompter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Paste", action: #selector(pasteText), keyEquivalent: "v")
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func pasteText() {
        prompterState.loadFromClipboard()
    }

    // MARK: - Status Bar

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "NotchPrompter")
            button.image?.size = NSSize(width: 16, height: 16)
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Toggle Panel", action: #selector(togglePanel), keyEquivalent: "t")
        menu.addItem(withTitle: "Open File...", action: #selector(openFileFromMenu), keyEquivalent: "o")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit NotchPrompter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu
    }

    @objc private func togglePanel() {
        prompterState.toggleExpanded()
    }

    @objc private func openFileFromMenu() {
        prompterState.openFile()
    }

    // MARK: - Panel Setup

    private func setupPanel() {
        let windowFrame = Self.windowFrame()

        let panel = FloatingPanel(
            contentRect: windowFrame,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isMovableByWindowBackground = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.animationBehavior = .none
        panel.acceptsMouseMovedEvents = true
        panel.isReleasedWhenClosed = false
        panel.appearance = NSAppearance(named: .darkAqua)

        let islandView = DynamicIslandView(state: prompterState)
            .environment(\.colorScheme, .dark)

        let hostingView = DragDropHostingView(rootView: islandView)
        hostingView.prompterState = prompterState
        hostingView.wantsLayer = true
        hostingView.layer?.isOpaque = false
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.frame = NSRect(origin: .zero, size: windowFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.sizingOptions = []
        hostingView.enableDragAndDrop()
        hostingView.onTextDropped = { [weak self] text in
            guard let self else { return }
            self.prompterState.scriptText = text
            self.prompterState.scriptFormat = self.prompterState.scriptText.contains("# ") ? .markdown : .plainText
            self.prompterState.resetScroll()
        }
        hostingView.onFileDropped = { [weak self] url in
            self?.prompterState.loadFromFile(url: url)
        }

        panel.contentView = hostingView
        self.panel = panel

        DispatchQueue.main.async {
            panel.orderFrontRegardless()
        }
    }

    static func builtInScreen() -> NSScreen {
        for screen in NSScreen.screens {
            if screen.safeAreaInsets.top > 0 {
                return screen
            }
        }
        return NSScreen.main ?? NSScreen.screens.first!
    }

    static func windowFrame() -> NSRect {
        let screen = builtInScreen()
        let screenFrame = screen.frame
        let x = screenFrame.origin.x + (screenFrame.width - panelWidth) / 2
        let y = screenFrame.origin.y + screenFrame.height - panelHeight
        return NSRect(x: x, y: y, width: panelWidth, height: panelHeight)
    }

    static func notchInfo() -> (width: CGFloat, height: CGFloat, hasNotch: Bool) {
        let screen = builtInScreen()
        let hasNotch = screen.safeAreaInsets.top > 0
        let notchHeight = hasNotch ? screen.safeAreaInsets.top : (screen.frame.maxY - screen.visibleFrame.maxY)
        var notchWidth: CGFloat = 200
        if let leftArea = screen.auxiliaryTopLeftArea,
           let rightArea = screen.auxiliaryTopRightArea {
            notchWidth = screen.frame.width - leftArea.width - rightArea.width + 4
        }
        return (notchWidth, notchHeight, hasNotch)
    }

    // MARK: - State Observation

    private func observeExpansionState() {
        var previouslyExpanded = false
        Timer.scheduledTimer(withTimeInterval: 1.0 / 10.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let expanded = self.prompterState.isExpanded

            if expanded != previouslyExpanded {
                previouslyExpanded = expanded

                if expanded {
                    NSApp.activate(ignoringOtherApps: true)
                    self.panel?.makeKeyAndOrderFront(nil)
                } else {
                    NSApp.deactivate()
                }
            }
        }
    }

    // MARK: - Mouse Passthrough

    private func setupMousePassthrough() {
        panel?.ignoresMouseEvents = true

        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self, let panel = self.panel else { return }
            let mouseLocation = NSEvent.mouseLocation
            let contentScreenRect = self.activeContentScreenRect()
            let isInContent = contentScreenRect.contains(mouseLocation)

            if panel.ignoresMouseEvents == isInContent {
                panel.ignoresMouseEvents = !isInContent
            }
        }
    }

    private func activeContentScreenRect() -> NSRect {
        guard let panel else { return .zero }
        let isExpanded = prompterState.isExpanded
        let notch = Self.notchInfo()
        let panelFrame = panel.frame

        let contentW: CGFloat
        let contentH: CGFloat

        if isExpanded {
            contentW = min(panelFrame.width, 500)
            contentH = prompterState.expandedHeight + 40
        } else {
            contentW = notch.width + 30
            contentH = notch.height + 10
        }

        let screenX = panelFrame.origin.x + (panelFrame.width - contentW) / 2
        let screenY = panelFrame.origin.y + panelFrame.height - contentH

        return NSRect(x: screenX, y: screenY, width: contentW, height: contentH)
    }

    // MARK: - Keyboard Shortcuts

    private var scrollMonitor: Any?

    private func setupKeyboardMonitor() {
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, self.prompterState.isExpanded else { return event }
            self.prompterState.manualScroll(by: event.scrollingDeltaY)
            return nil
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.prompterState.isExpanded else { return event }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isCmd = flags.contains(.command)

            switch event.keyCode {
            case 49: // Space
                self.prompterState.togglePlayPause()
                return nil
            case 126: // Up Arrow
                self.prompterState.increaseSpeed()
                return nil
            case 125: // Down Arrow
                self.prompterState.decreaseSpeed()
                return nil
            case 53: // Escape
                self.prompterState.toggleExpanded()
                return nil
            case 124: // Right Arrow
                self.prompterState.jumpToNextHeader()
                return nil
            case 123: // Left Arrow
                self.prompterState.jumpToPreviousHeader()
                return nil
            default:
                break
            }

            if isCmd {
                switch event.charactersIgnoringModifiers {
                case "v":
                    self.prompterState.loadFromClipboard()
                    return nil
                case "o":
                    self.prompterState.openFile()
                    return nil
                case "=", "+":
                    self.prompterState.increaseFontSize()
                    return nil
                case "-":
                    self.prompterState.decreaseFontSize()
                    return nil
                case "0":
                    self.prompterState.resetFontSize()
                    return nil
                default:
                    break
                }
            }

            return event
        }
    }

    deinit {
        if let monitor = keyMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = scrollMonitor { NSEvent.removeMonitor(monitor) }
    }
}
