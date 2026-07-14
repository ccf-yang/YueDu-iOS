import Foundation

/// HTML 解析工具类（简单实现，用于基本的规则提取）
class HTMLParser {
    static let shared = HTMLParser()
    
    /// 使用正则表达式提取内容
    func extractByRegex(_ html: String, pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            return matches.compactMap { match -> String? in
                if match.numberOfRanges > 1 {
                    if let range = Range(match.range(at: 1), in: html) {
                        return String(html[range])
                    }
                } else if let range = Range(match.range, in: html) {
                    return String(html[range])
                }
                return nil
            }
        } catch {
            return []
        }
    }
    
    /// 提取 HTML 标签之间的内容
    func extractBetween(_ html: String, startTag: String, endTag: String) -> [String] {
        let pattern = "\\(startTag)([\\s\\S]*?)\\(endTag)"
        return extractByRegex(html, pattern: pattern)
    }
    
    /// 提取所有链接
    func extractLinks(_ html: String) -> [(title: String, url: String)] {
        let pattern = "<a[^>]*href=[\"']?([^\"'>\\s]+)[\"']?[^>]*>([^<]+)</a>"
        let urls = extractByRegex(html, pattern: "href=[\"']?([^\"'>\\s]+)")
        let titles = extractByRegex(html, pattern: ">([^<]+)</a>")
        
        return zip(titles, urls).map { (title: $0, url: $1) }
    }
    
    /// 提取图片 URL
    func extractImages(_ html: String) -> [String] {
        let pattern = "<img[^>]*src=[\"']?([^\"'>\\s]+)"
        return extractByRegex(html, pattern: pattern)
    }
    
    /// 提取 JSON-LD 数据
    func extractJSONLD(_ html: String) -> [[String: Any]]? {
        let pattern = "<script[^>]*type=[\"']application/ld\\+json[\"']>([\\s\\S]*?)</script>"
        let jsonStrings = extractByRegex(html, pattern: pattern)
        
        var results: [[String: Any]] = []
        for jsonString in jsonStrings {
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                results.append(json)
            }
        }
        
        return results.isEmpty ? nil : results
    }
    
    /// 使用 XPath 样式的选择器提取内容（简化版）
    func extractBySelector(_ html: String, selector: String) -> [String] {
        // 这是一个简化的实现，真实的 XPath 需要更复杂的解析
        // 仅支持基本的 CSS 选择器模式
        
        if selector.contains("class=") {
            let pattern = "class=[\"']([^\"']*\\(selector)[^\"']*)[\"\']"
            return extractByRegex(html, pattern: pattern)
        } else if selector.contains("id=") {
            let pattern = "id=[\"'](\\(selector))[\"']"
            return extractByRegex(html, pattern: pattern)
        }
        
        return []
    }
}
