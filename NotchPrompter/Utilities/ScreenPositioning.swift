import AppKit

enum ScreenPositioning {
    static func notchWindowFrame(expanded: Bool) -> NSRect {
        AppDelegate.windowFrame()
    }
}
