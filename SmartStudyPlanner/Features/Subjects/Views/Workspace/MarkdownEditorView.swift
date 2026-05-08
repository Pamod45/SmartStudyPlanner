import SwiftUI
import UIKit

enum FormatAction {
    case bold
    case italic
    case underline
    case title
    case subtitle
    case body
    case bullet
    case quote
}


struct RichTextEditorView: UIViewRepresentable {
    @Binding var storage: NSAttributedString
    var theme: AppTheme
    var onTextViewReady: (UITextView) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .clear
        tv.isScrollEnabled = true
        tv.showsVerticalScrollIndicator = false
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 80, right: 16)
        tv.keyboardDismissMode = .interactive
        tv.tintColor = UIColor(theme.colors.primary)
        tv.typingAttributes = defaultAttributes(theme: theme)

        if #available(iOS 18.0, *) {
            tv.writingToolsBehavior = .complete
        }

        let attributed = NSMutableAttributedString(attributedString: storage)
        if attributed.length == 0 {
            tv.attributedText = NSAttributedString(string: "", attributes: defaultAttributes(theme: theme))
        } else {
            attributed.addAttribute(.foregroundColor, value: UIColor(theme.colors.textPrimary), range: NSRange(location: 0, length: attributed.length))
            tv.attributedText = attributed
        }

        DispatchQueue.main.async {
            onTextViewReady(tv)
            tv.becomeFirstResponder()
        }
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.attributedText != storage && !context.coordinator.isEditing {
            let sel = tv.selectedRange
            let attributed = NSMutableAttributedString(attributedString: storage)
            attributed.addAttribute(.foregroundColor, value: UIColor(theme.colors.textPrimary), range: NSRange(location: 0, length: attributed.length))
            tv.attributedText = attributed
            tv.selectedRange = sel
        }
        tv.tintColor = UIColor(theme.colors.primary)
        tv.typingAttributes = defaultAttributes(theme: theme)
    }

    func defaultAttributes(theme: AppTheme) -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor(theme.colors.textPrimary)
        ]
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditorView
        var isEditing = false

        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.storage = textView.attributedText
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                handleNewline(textView: textView, range: range)
                return false
            }
            return true
        }

        private func handleNewline(textView: UITextView, range: NSRange) {
            let nsText = textView.attributedText.string as NSString
            let lineRange = nsText.lineRange(for: range)
            let lineText = nsText.substring(with: lineRange)

            let isBullet = lineText.hasPrefix("• ")
            let isQuote  = lineText.hasPrefix("    ")

            let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
            let insertionPoint = range.location + range.length

            var newLineText = "\n"
            var typingAttrs = parent.defaultAttributes(theme: parent.theme)

            if isBullet {
                let stripped = lineText.trimmingCharacters(in: .whitespacesAndNewlines).dropFirst(2)
                if stripped.isEmpty {
                    let removeRange = NSRange(location: lineRange.location, length: lineRange.length)
                    mutable.replaceCharacters(in: removeRange, with: "\n")
                    textView.attributedText = mutable
                    let newPos = lineRange.location + 1
                    textView.selectedRange = NSRange(location: newPos, length: 0)
                    parent.storage = textView.attributedText
                    return
                }
                newLineText = "\n• "
                typingAttrs[.font] = UIFont.systemFont(ofSize: 16)
            } else if isQuote {
                newLineText = "\n    "
                typingAttrs[.font] = UIFont.italicSystemFont(ofSize: 15)
            }

            let insertAttr = NSAttributedString(string: newLineText, attributes: typingAttrs)
            mutable.insert(insertAttr, at: insertionPoint)
            textView.attributedText = mutable
            textView.selectedRange = NSRange(location: insertionPoint + newLineText.count, length: 0)
            textView.typingAttributes = typingAttrs
            parent.storage = textView.attributedText
        }
    }
}

struct MarkdownEditorView: View {
    @Environment(\.theme) var theme
    @Binding var storage: NSAttributedString
    @State private var tvRef: UITextView? = nil

    var body: some View {
        VStack(spacing: 0) {
            RichTextEditorView(storage: $storage, theme: theme) { tv in
                tvRef = tv
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            formattingToolbar
        }
    }

    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                toolbarButton(label: "Title",    labelFont: .system(size: 15, weight: .bold))   { applyFormat(.title) }
                toolbarButton(label: "Subtitle", labelFont: .system(size: 13, weight: .regular)) { applyFormat(.subtitle) }
                toolbarButton(label: "Body",     labelFont: .system(size: 13, weight: .regular)) { applyFormat(.body) }

                divider

                toolbarIconButton("bold")        { applyFormat(.bold) }
                toolbarIconButton("italic")      { applyFormat(.italic) }
                toolbarIconButton("underline")   { applyFormat(.underline) }

                divider

                toolbarIconButton("list.bullet") { applyFormat(.bullet) }
                toolbarIconButton("text.quote")  { applyFormat(.quote) }
            }
            .padding(.horizontal, theme.spacing.sm)
        }
        .frame(height: 52)
        .background(theme.colors.surface)
        .overlay(Rectangle().fill(theme.colors.border.opacity(0.3)).frame(height: 0.5), alignment: .top)
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.colors.border.opacity(0.4))
            .frame(width: 1, height: 24)
            .padding(.horizontal, theme.spacing.sm)
    }

    private func toolbarButton(label: String, labelFont: Font, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(labelFont)
                .foregroundColor(theme.colors.textPrimary)
                .frame(minWidth: 52, minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private func toolbarIconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    private func applyFormat(_ action: FormatAction) {
        guard let tv = tvRef else { return }
        let selectedRange = tv.selectedRange
        guard selectedRange.length > 0 || action == .bullet || action == .quote || action == .title || action == .subtitle || action == .body else { return }

        let mutable = NSMutableAttributedString(attributedString: tv.attributedText)
        let nsText = tv.attributedText.string as NSString
        let effectiveRange = selectedRange.length > 0
            ? selectedRange
            : nsText.lineRange(for: selectedRange)

        switch action {
        case .bold:
            mutable.enumerateAttribute(.font, in: effectiveRange) { value, range, _ in
                let current = (value as? UIFont) ?? UIFont.systemFont(ofSize: 16)
                let isBold = current.fontDescriptor.symbolicTraits.contains(.traitBold)
                let newFont = isBold
                    ? UIFont.systemFont(ofSize: current.pointSize, weight: .regular)
                    : UIFont.boldSystemFont(ofSize: current.pointSize)
                mutable.addAttribute(.font, value: newFont, range: range)
            }

        case .italic:
            mutable.enumerateAttribute(.font, in: effectiveRange) { value, range, _ in
                let current = (value as? UIFont) ?? UIFont.systemFont(ofSize: 16)
                let isItalic = current.fontDescriptor.symbolicTraits.contains(.traitItalic)
                let newFont = isItalic
                    ? UIFont.systemFont(ofSize: current.pointSize)
                    : UIFont.italicSystemFont(ofSize: current.pointSize)
                mutable.addAttribute(.font, value: newFont, range: range)
            }

        case .underline:
            mutable.enumerateAttribute(.underlineStyle, in: effectiveRange) { value, range, _ in
                let isUnderlined = (value as? Int) == NSUnderlineStyle.single.rawValue
                if isUnderlined {
                    mutable.removeAttribute(.underlineStyle, range: range)
                } else {
                    mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                }
            }

        case .title:
            let lineRange = nsText.lineRange(for: selectedRange)
            mutable.addAttributes([
                .font: UIFont.boldSystemFont(ofSize: 26),
                .foregroundColor: UIColor(theme.colors.textPrimary)
            ], range: lineRange)

        case .subtitle:
            let lineRange = nsText.lineRange(for: selectedRange)
            mutable.addAttributes([
                .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
                .foregroundColor: UIColor(theme.colors.textPrimary)
            ], range: lineRange)

        case .body:
            let lineRange = nsText.lineRange(for: selectedRange)
            mutable.addAttributes([
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor(theme.colors.textPrimary)
            ], range: lineRange)

        case .bullet:
            let lineRange = nsText.lineRange(for: selectedRange)
            let lineText = nsText.substring(with: lineRange)
            let newLine = lineText.hasPrefix("• ")
                ? String(lineText.dropFirst(2))
                : "• " + lineText
            let replacement = NSAttributedString(string: newLine, attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor(theme.colors.textPrimary)
            ])
            mutable.replaceCharacters(in: lineRange, with: replacement)
            tv.typingAttributes = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor(theme.colors.textPrimary)
            ]

        case .quote:
            let lineRange = nsText.lineRange(for: selectedRange)
            let lineText = nsText.substring(with: lineRange)
            let newLine = lineText.hasPrefix("    ")
                ? String(lineText.dropFirst(4))
                : "    " + lineText
            let replacement = NSAttributedString(string: newLine, attributes: [
                .font: UIFont.italicSystemFont(ofSize: 15),
                .foregroundColor: UIColor(theme.colors.textSecondary)
            ])
            mutable.replaceCharacters(in: lineRange, with: replacement)
        }

        tv.attributedText = mutable
        tv.selectedRange = selectedRange
        storage = mutable
        tv.typingAttributes = currentTypingAttributes(tv: tv, at: selectedRange)
    }

    private func currentTypingAttributes(tv: UITextView, at range: NSRange) -> [NSAttributedString.Key: Any] {
        guard range.location < tv.attributedText.length else {
            return [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor(theme.colors.textPrimary)
            ]
        }
        return tv.attributedText.attributes(at: range.location, effectiveRange: nil)
    }
}
