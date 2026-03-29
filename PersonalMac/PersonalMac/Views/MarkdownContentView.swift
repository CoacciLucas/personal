import SwiftUI

struct MarkdownContentView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(parseSegments().enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let text):
                    renderTextBlock(text)
                case .code(let language, let code):
                    codeBlockView(language: language, code: code)
                }
            }
        }
    }

    // MARK: - Text Block Rendering

    @ViewBuilder
    private func renderTextBlock(_ text: String) -> some View {
        let lines = text.components(separatedBy: "\n")
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    Spacer().frame(height: 4)
                } else if trimmed.hasPrefix("### ") {
                    Text(inlineMarkdown(String(trimmed.dropFirst(4))))
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, 4)
                } else if trimmed.hasPrefix("## ") {
                    Text(inlineMarkdown(String(trimmed.dropFirst(3))))
                        .font(.system(size: 15, weight: .bold))
                        .padding(.top, 6)
                } else if trimmed.hasPrefix("# ") {
                    Text(inlineMarkdown(String(trimmed.dropFirst(2))))
                        .font(.system(size: 17, weight: .bold))
                        .padding(.top, 8)
                } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 6) {
                        Text("\u{2022}")
                            .font(.system(size: 13))
                        Text(inlineMarkdown(String(trimmed.dropFirst(2))))
                            .font(.system(size: 13))
                    }
                } else if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                    let number = String(trimmed[match])
                    let rest = String(trimmed[match.upperBound...])
                    HStack(alignment: .top, spacing: 4) {
                        Text(number)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(inlineMarkdown(rest))
                            .font(.system(size: 13))
                    }
                } else {
                    Text(inlineMarkdown(trimmed))
                        .font(.system(size: 13))
                }
            }
        }
        .textSelection(.enabled)
    }

    // MARK: - Inline Markdown → AttributedString

    private func inlineMarkdown(_ text: String) -> AttributedString {
        // Use Apple's built-in markdown parser for inline formatting
        // Handles **bold**, *italic*, `code`, [links](url), etc.
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        return AttributedString(text)
    }

    // MARK: - Code Block

    @ViewBuilder
    private func codeBlockView(language: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if !language.isEmpty {
                    Text(language)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                        Text("Copiar")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.12))

            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
            }
        }
        .background(Color.black.opacity(0.06))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Top-level Parsing (code blocks vs text)

    enum Segment {
        case text(String)
        case code(language: String, code: String)
    }

    func parseSegments() -> [Segment] {
        var segments: [Segment] = []
        var remaining = content

        while let startRange = remaining.range(of: "```") {
            let textBefore = String(remaining[remaining.startIndex..<startRange.lowerBound])
            if !textBefore.isEmpty {
                segments.append(.text(textBefore))
            }

            remaining = String(remaining[startRange.upperBound...])

            var language = ""
            if let newlineIndex = remaining.firstIndex(of: "\n") {
                language = String(remaining[remaining.startIndex..<newlineIndex])
                    .trimmingCharacters(in: .whitespaces)
                remaining = String(remaining[remaining.index(after: newlineIndex)...])
            }

            if let endRange = remaining.range(of: "```") {
                let code = String(remaining[remaining.startIndex..<endRange.lowerBound])
                    .trimmingCharacters(in: .newlines)
                segments.append(.code(language: language, code: code))
                remaining = String(remaining[endRange.upperBound...])
            } else {
                segments.append(.code(language: language, code: remaining.trimmingCharacters(in: .newlines)))
                remaining = ""
            }
        }

        if !remaining.isEmpty {
            segments.append(.text(remaining))
        }

        return segments
    }
}
