import Foundation

/// 字符串工具类
class StringUtils {
    static let shared = StringUtils()
    
    /// 去除 HTML 标签
    func stripHTML(_ html: String) -> String {
        var text = html
        // 移除脚本标签
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        // 移除样式标签
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        // 移除所有 HTML 标签
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        // 解码 HTML 实体
        text = decodeHTMLEntities(text)
        // 去除多余空白
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        return text
    }
    
    /// 解码 HTML 实体
    private func decodeHTMLEntities(_ text: String) -> String {
        var result = text
        let entities = [
            "&quot;": "\"",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&nbsp;": " ",
            "&mdash;": "—",
            "&ndash;": "–",
            "&apos;": "'"
        ]
        
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        
        return result
    }
    
    /// 截取字符串（按字符数）
    func truncate(_ string: String, to length: Int, suffix: String = "...") -> String {
        guard string.count > length else { return string }
        let index = string.index(string.startIndex, offsetBy: length)
        return String(string[..<index]) + suffix
    }
    
    /// 计算字符串长度（中文占2个字符）
    func chineseLength(_ string: String) -> Int {
        var length = 0
        for char in string {
            let charStr = String(char)
            let range = charStr.rangeOfCharacter(from: CharacterSet.controlCharacters)
            if range != nil {
                length += 2
            } else {
                length += 1
            }
        }
        return length
    }
    
    /// 检查是否为有效的 URL
    func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme != nil && url.host != nil
    }
    
    /// 提取 URL 中的域名
    func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host else { return nil }
        let components = host.components(separatedBy: ".")
        if components.count >= 2 {
            return components[components.count - 2]
        }
        return host
    }
    
    /// 清理书名（去除特殊字符）
    func sanitizeBookName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.components(separatedBy: invalidChars).joined(separator: "_").trimmingCharacters(in: .whitespaces)
    }
}
