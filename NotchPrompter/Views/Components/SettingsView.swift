import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Bindable var state: PrompterState
    @State private var speed: Double = AppSettings.shared.defaultSpeed
    @State private var fontSize: Double = AppSettings.shared.defaultFontSize
    @State private var autoPlay: Bool = AppSettings.shared.autoPlayOnOpen
    @State private var filePath: String = AppSettings.shared.defaultFilePath

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Settings")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: resetAll) {
                    Text("Reset")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Theme")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.gray)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 8)], spacing: 8) {
                    ForEach(PrompterTheme.allCases) { theme in
                        let isSelected = state.theme == theme
                        Button(action: {
                            state.theme = theme
                            AppSettings.shared.theme = theme.rawValue
                        }) {
                            VStack(spacing: 4) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(LinearGradient(colors: theme.previewColors, startPoint: .top, endPoint: .bottom))
                                        .frame(height: 32)

                                    Image(systemName: theme.iconName)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(theme.textColor.opacity(0.8))
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(isSelected ? Color.accentColor : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 0.5)
                                )

                                Text(theme.displayName)
                                    .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                                    .foregroundStyle(isSelected ? Color.accentColor : .white.opacity(0.6))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            settingRow(title: "Speed") {
                HStack(spacing: 6) {
                    Slider(value: $speed, in: 0.25...3.0, step: 0.25)
                        .frame(width: 100)
                    Text(String(format: "%.1fx", speed))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.gray)
                        .frame(width: 35, alignment: .trailing)
                }
            }

            settingRow(title: "Font Size") {
                HStack(spacing: 6) {
                    Slider(value: $fontSize, in: 16...48, step: 2)
                        .frame(width: 100)
                    Text("\(Int(fontSize))pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.gray)
                        .frame(width: 35, alignment: .trailing)
                }
            }

            settingRow(title: "Auto-play") {
                Toggle("", isOn: $autoPlay)
                    .toggleStyle(.switch)
                    .scaleEffect(0.7)
                    .frame(width: 40)
            }

            settingRow(title: "Opacity") {
                HStack(spacing: 6) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 8))
                        .foregroundStyle(.gray)
                    Slider(value: Binding(
                        get: { state.panelOpacity },
                        set: { state.panelOpacity = $0 }
                    ), in: 0.3...1.0, step: 0.1)
                    .frame(width: 100)
                    Image(systemName: "eye")
                        .font(.system(size: 8))
                        .foregroundStyle(.gray)
                    Text("\(Int(state.panelOpacity * 100))%")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.gray)
                        .frame(width: 28, alignment: .trailing)
                }
            }

            settingRow(title: "Focus Line") {
                Toggle("", isOn: Binding(
                    get: { state.showFocusLine },
                    set: { state.showFocusLine = $0 }
                ))
                .toggleStyle(.switch)
                .scaleEffect(0.7)
                .frame(width: 40)
            }

            settingRow(title: "Countdown") {
                HStack(spacing: 6) {
                    Slider(value: Binding(
                        get: { state.countdownMinutes },
                        set: {
                            state.countdownMinutes = $0
                            AppSettings.shared.countdownMinutes = $0
                        }
                    ), in: 0...30, step: 1)
                    .frame(width: 100)
                    Text(state.countdownMinutes > 0 ? "\(Int(state.countdownMinutes))m" : "Off")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.gray)
                        .frame(width: 28, alignment: .trailing)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Default File")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.gray)

                HStack(spacing: 6) {
                    Text(filePath.isEmpty ? "None" : URL(fileURLWithPath: filePath).lastPathComponent)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(filePath.isEmpty ? .gray : .white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("Browse") { browseFile() }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))

                    if !filePath.isEmpty {
                        Button(action: { filePath = "" }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            speed = AppSettings.shared.defaultSpeed
            fontSize = AppSettings.shared.defaultFontSize
            autoPlay = AppSettings.shared.autoPlayOnOpen
            filePath = AppSettings.shared.defaultFilePath
        }
        .onChange(of: speed) { _, newVal in
            AppSettings.shared.defaultSpeed = newVal
            state.scrollSpeed = newVal
        }
        .onChange(of: fontSize) { _, newVal in
            AppSettings.shared.defaultFontSize = newVal
            state.fontSize = CGFloat(newVal)
        }
        .onChange(of: autoPlay) { _, newVal in
            AppSettings.shared.autoPlayOnOpen = newVal
        }
        .onChange(of: filePath) { _, newVal in
            AppSettings.shared.defaultFilePath = newVal
            if !newVal.isEmpty {
                state.loadFromFile(url: URL(fileURLWithPath: newVal))
            }
        }
    }

    private func settingRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.gray)
                .frame(width: 80, alignment: .leading)
            content()
        }
    }

    private func resetAll() {
        speed = 1.0
        fontSize = 24
        autoPlay = false
        filePath = ""

        AppSettings.shared.defaultSpeed = 1.0
        AppSettings.shared.defaultFilePath = ""
        AppSettings.shared.defaultFontSize = 24
        AppSettings.shared.autoPlayOnOpen = false

        state.scrollSpeed = 1.0
        state.fontSize = 24
    }

    private func browseFile() {
        state.showSettings = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowedContentTypes = [.plainText, .text, .rtf, .data]
            panel.allowsOtherFileTypes = true
            panel.title = "Select Default Script File"
            panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 5)

            if panel.runModal() == .OK, let url = panel.url {
                self.filePath = url.path
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.state.showSettings = true
            }
        }
    }
}
