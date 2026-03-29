import SwiftUI

struct MarkdownContentView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(parseSegments().enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let text):
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(text.trimmingCharacters(in: .newlines))
                            .textSelection(.enabled)
                    }
                case .code(let language, let code):
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
            }
        }
    }

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
