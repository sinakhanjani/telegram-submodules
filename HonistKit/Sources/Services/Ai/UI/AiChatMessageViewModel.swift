import UIKit
import Foundation
import HonistDesignSystem

public struct AiChatMessageViewModel {
    public let id: String
    public let text: String
    public let isOutgoing: Bool        // true = user (right), false = assistant (left)
    public let date: Date

    public let textAlignment: NSTextAlignment
    public let baseWritingDirection: NSWritingDirection
    public let attributedText: NSAttributedString

    public init(message: AiMessageDTO) {
        // ✅ نرمال‌سازی \n و \t اگر به صورت "\\n" از سرور اومده باشه
        let normalizedContent = message.content
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\t", with: "\t")

        self.id = message.id
        self.text = normalizedContent
        self.date = message.createdAt

        // role == "user" -> outgoing (right bubble)
        self.isOutgoing = (message.role.lowercased() == "user")

        // Simple RTL detection for Persian/Arabic text
        let isRTL = AiChatMessageViewModel.containsRTLCharacters(in: normalizedContent)

        if isRTL {
            self.textAlignment = .right
            self.baseWritingDirection = .rightToLeft
        } else {
            self.textAlignment = .left
            self.baseWritingDirection = .leftToRight
        }

        // 🔹 ساختن attributedText از Markdown بدون دست‌کاری paragraphStyle
        self.attributedText = AiChatMessageViewModel.makeNormalizedAttributedText(
            from: normalizedContent,
            isOutgoing: self.isOutgoing
        )
    }

    public static func containsRTLCharacters(in text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // Arabic, Persian and similar ranges
            if (0x0600...0x06FF).contains(scalar.value) ||
               (0x0750...0x077F).contains(scalar.value) ||
               (0x08A0...0x08FF).contains(scalar.value) {
                return true
            }
        }
        return false
    }

    // MARK: - Markdown-lite → NSAttributedString (حفظ \n و اعداد، فقط bold و ###)

    public static func makeNormalizedAttributedText(from text: String,
                                                     isOutgoing: Bool) -> NSAttributedString {
        let baseFont = DS.Font.body()
        let boldFont = UIFont.systemFont(ofSize: baseFont.pointSize, weight: .semibold)

        // متن رو خط به خط می‌بریم تا راحت bold و heading رو روی هر خط اعمال کنیم
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

        let result = NSMutableAttributedString()

        for (index, rawLineSub) in lines.enumerated() {
            var line = String(rawLineSub)
            var isHeading = false

            // اگر با "### " شروع شده، marker رو بردار و کل خط رو heading در نظر بگیر
            if line.hasPrefix("### ") {
                isHeading = true
                line.removeFirst(4)
            }

            // اول کل خط رو با فونت معمولی می‌سازیم
            let lineAttr = NSMutableAttributedString(
                string: line,
                attributes: [.font: baseFont]
            )

            // --- پردازش **bold** داخل همین خط ---
            let pattern = "\\*\\*(.+?)\\*\\*"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsLine = line as NSString
                let fullRange = NSRange(location: 0, length: nsLine.length)
                let matches = regex.matches(in: line, options: [], range: fullRange)

                // از آخر به اول می‌ریم که indexها بعد از حذف "**" به هم نریزه
                for match in matches.reversed() {
                    let innerRange = match.range(at: 1)

                    // bold برای متن داخل ** **
                    lineAttr.addAttribute(.font, value: boldFont, range: innerRange)

                    // حذف ** پایانی
                    let endMarkerRange = NSRange(
                        location: match.range.location + match.range.length - 2,
                        length: 2
                    )
                    lineAttr.replaceCharacters(in: endMarkerRange, with: "")

                    // حذف ** ابتدایی
                    let startMarkerRange = NSRange(
                        location: match.range.location,
                        length: 2
                    )
                    lineAttr.replaceCharacters(in: startMarkerRange, with: "")
                }
            }

            // اگر heading بود، کل خط رو bold کن
            if isHeading && lineAttr.length > 0 {
                let headingRange = NSRange(location: 0, length: lineAttr.length)
                lineAttr.addAttribute(.font, value: boldFont, range: headingRange)
            }

            // خط آماده شده رو به result اضافه کن
            result.append(lineAttr)

            // اگر آخرین خط نیستیم، یک \n اضافه کن تا ساختار متن حفظ بشه
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: [.font: baseFont]))
            }
        }

        // paragraphStyle کلی (فقط برای lineSpacing و word wrapping)
        let fullRange = NSRange(location: 0, length: result.length)
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.lineSpacing = 3
        result.addAttribute(.paragraphStyle, value: style, range: fullRange)

        return result
    }
}
