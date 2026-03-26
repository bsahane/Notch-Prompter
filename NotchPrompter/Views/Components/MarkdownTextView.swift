import SwiftUI

struct MarkdownTextView: View {
    let text: String
    let fontSize: CGFloat
    var onHeaderPositions: ([HeaderPosition]) -> Void = { _ in }

    private var blocks: [MarkdownBlock] {
        parseMarkdown(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                blockView(block)
                    .background(
                        isHeader(block.kind) ? GeometryReader { geo in
                            Color.clear.preference(
                                key: HeaderPositionKey.self,
                                value: [HeaderPosition(title: block.content, offset: geo.frame(in: .named("scrollContent")).minY)]
                            )
                        } : nil
                    )
            }
        }
        .coordinateSpace(name: "scrollContent")
        .onPreferenceChange(HeaderPositionKey.self) { positions in
            onHeaderPositions(positions)
        }
    }

    private func isHeader(_ kind: MarkdownBlockKind) -> Bool {
        kind == .h1 || kind == .h2 || kind == .h3
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block.kind {
        case .h1:
            styledText(block.content, size: fontSize + 8, weight: .bold, color: .white)
                .padding(.top, 8)
                .padding(.bottom, 4)

        case .h2:
            styledText(block.content, size: fontSize + 4, weight: .bold, color: Color(nsColor: NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)))
                .padding(.top, 6)
                .padding(.bottom, 2)

        case .h3:
            styledText(block.content, size: fontSize + 2, weight: .semibold, color: Color(nsColor: NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1)))
                .padding(.top, 4)

        case .blockquote:
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(nsColor: NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.6)))
                    .frame(width: 3)

                styledText(block.content, size: fontSize - 2, weight: .regular, color: .white.opacity(0.6))
                    .italic()
            }
            .padding(.vertical, 2)

        case .horizontalRule:
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
                .padding(.vertical, 6)

        case .bullet:
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(Color(nsColor: NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)))
                    .frame(width: 5, height: 5)
                    .offset(y: 2)

                styledText(block.content, size: fontSize - 2, weight: .regular, color: .white.opacity(0.85))
            }

        case .numbered(let num):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(num).")
                    .font(.system(size: fontSize - 2, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(nsColor: NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)))
                    .frame(width: 20, alignment: .trailing)

                styledText(block.content, size: fontSize - 2, weight: .regular, color: .white.opacity(0.85))
            }

        case .codeBlock:
            Text(block.content)
                .font(.system(size: fontSize - 4, design: .monospaced))
                .foregroundStyle(Color(nsColor: NSColor(red: 0.6, green: 0.9, blue: 0.6, alpha: 1)))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))

        case .paragraph:
            styledText(block.content, size: fontSize, weight: .regular, color: .white.opacity(0.88))

        case .empty:
            Spacer().frame(height: 4)
        }
    }

    private func styledText(_ raw: String, size: CGFloat, weight: Font.Weight, color: Color) -> Text {
        var result = Text("")
        var remaining = raw

        while !remaining.isEmpty {
            if let boldRange = remaining.range(of: "\\*\\*(.+?)\\*\\*", options: .regularExpression) {
                let before = String(remaining[remaining.startIndex..<boldRange.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before)
                        .font(.system(size: size, weight: weight))
                        .foregroundColor(color)
                }

                let matched = String(remaining[boldRange])
                let inner = String(matched.dropFirst(2).dropLast(2))
                result = result + Text(inner)
                    .font(.system(size: size, weight: .bold))
                    .foregroundColor(.white)

                remaining = String(remaining[boldRange.upperBound...])
            } else if let italicRange = remaining.range(of: "\\*(.+?)\\*", options: .regularExpression) {
                let before = String(remaining[remaining.startIndex..<italicRange.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before)
                        .font(.system(size: size, weight: weight))
                        .foregroundColor(color)
                }

                let matched = String(remaining[italicRange])
                let inner = String(matched.dropFirst(1).dropLast(1))
                result = result + Text(inner)
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color.opacity(0.7))
                    .italic()

                remaining = String(remaining[italicRange.upperBound...])
            } else if let codeRange = remaining.range(of: "`(.+?)`", options: .regularExpression) {
                let before = String(remaining[remaining.startIndex..<codeRange.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before)
                        .font(.system(size: size, weight: weight))
                        .foregroundColor(color)
                }

                let matched = String(remaining[codeRange])
                let inner = String(matched.dropFirst(1).dropLast(1))
                result = result + Text(inner)
                    .font(.system(size: size - 2, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(nsColor: NSColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1)))

                remaining = String(remaining[codeRange.upperBound...])
            } else {
                result = result + Text(remaining)
                    .font(.system(size: size, weight: weight))
                    .foregroundColor(color)
                break
            }
        }

        return result
    }
}

// MARK: - Markdown Parsing

enum MarkdownBlockKind: Equatable {
    case h1, h2, h3
    case paragraph
    case blockquote
    case horizontalRule
    case bullet
    case numbered(Int)
    case codeBlock
    case empty
}

struct MarkdownBlock {
    let kind: MarkdownBlockKind
    let content: String
}

private func parseMarkdown(_ text: String) -> [MarkdownBlock] {
    let lines = text.components(separatedBy: "\n")
    var blocks: [MarkdownBlock] = []
    var inCodeBlock = false
    var codeContent = ""

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("```") {
            if inCodeBlock {
                blocks.append(MarkdownBlock(kind: .codeBlock, content: codeContent.trimmingCharacters(in: .newlines)))
                codeContent = ""
                inCodeBlock = false
            } else {
                inCodeBlock = true
            }
            continue
        }

        if inCodeBlock {
            codeContent += (codeContent.isEmpty ? "" : "\n") + line
            continue
        }

        if trimmed.isEmpty {
            blocks.append(MarkdownBlock(kind: .empty, content: ""))
        } else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
            blocks.append(MarkdownBlock(kind: .horizontalRule, content: ""))
        } else if trimmed.hasPrefix("### ") {
            blocks.append(MarkdownBlock(kind: .h3, content: String(trimmed.dropFirst(4))))
        } else if trimmed.hasPrefix("## ") {
            blocks.append(MarkdownBlock(kind: .h2, content: String(trimmed.dropFirst(3))))
        } else if trimmed.hasPrefix("# ") {
            blocks.append(MarkdownBlock(kind: .h1, content: String(trimmed.dropFirst(2))))
        } else if trimmed.hasPrefix("> ") {
            blocks.append(MarkdownBlock(kind: .blockquote, content: String(trimmed.dropFirst(2))))
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            blocks.append(MarkdownBlock(kind: .bullet, content: String(trimmed.dropFirst(2))))
        } else if let match = trimmed.range(of: "^(\\d+)\\. ", options: .regularExpression) {
            let numStr = String(trimmed[trimmed.startIndex..<match.upperBound]).trimmingCharacters(in: .whitespaces).dropLast(2)
            let num = Int(numStr) ?? 1
            let content = String(trimmed[match.upperBound...])
            blocks.append(MarkdownBlock(kind: .numbered(num), content: content))
        } else {
            blocks.append(MarkdownBlock(kind: .paragraph, content: trimmed))
        }
    }

    if inCodeBlock && !codeContent.isEmpty {
        blocks.append(MarkdownBlock(kind: .codeBlock, content: codeContent))
    }

    return blocks
}

struct HeaderPosition: Equatable {
    let title: String
    let offset: CGFloat
}

struct HeaderPositionKey: PreferenceKey {
    static var defaultValue: [HeaderPosition] = []
    static func reduce(value: inout [HeaderPosition], nextValue: () -> [HeaderPosition]) {
        value.append(contentsOf: nextValue())
    }
}
