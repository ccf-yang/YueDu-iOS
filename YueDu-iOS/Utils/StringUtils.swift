import Foundation

/// 字符串工具类
class StringUtils {
    static let shared = StringUtils()

    /// 去除 HTML 标签并解码实体
    func stripHTML(_ html: String) -> String {
        var text = html
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<p[^>]*>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = decodeHTMLEntities(text)
        text = text.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        let map: [String: String] = [
            "&quot;": "\"", "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&nbsp;": " ", "&mdash;": "—", "&ndash;": "–", "&apos;": "'",
            "&#39;": "'", "&#34;": "\"", "&hellip;": "…", "&middot;": "·"
        ]
        map.forEach { result = result.replacingOccurrences(of: $0.key, with: $0.value) }
        // 解码数字实体 &#NNN;
        if let re = try? NSRegularExpression(pattern: "&#(\\d+);") {
            let range = NSRange(result.startIndex..., in: result)
            let matches = re.matches(in: result, range: range).reversed()
            for m in matches {
                if let r = Range(m.range(at: 1), in: result),
                   let code = UInt32(result[r]),
                   let scalar = Unicode.Scalar(code) {
                    result.replaceSubrange(Range(m.range, in: result)!, with: String(Character(scalar)))
                }
            }
        }
        return result
    }

    func truncate(_ string: String, to length: Int, suffix: String = "...") -> String {
        guard string.count > length else { return string }
        return String(string.prefix(length)) + suffix
    }

    func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme != nil && url.host != nil
    }

    func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString), let host = url.host else { return nil }
        let parts = host.components(separatedBy: ".")
        return parts.count >= 2 ? parts[parts.count - 2] : host
    }

    func sanitizeFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.components(separatedBy: invalid).joined(separator: "_")
            .trimmingCharacters(in: .whitespaces)
    }
}
