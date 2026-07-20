import Foundation

/// HTML 解析工具类
class HTMLParser {
    static let shared = HTMLParser()

    // MARK: - 正则提取

    func extractByRegex(_ html: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, range: range)
        return matches.compactMap { match -> String? in
            let idx = match.numberOfRanges > 1 ? 1 : 0
            guard let r = Range(match.range(at: idx), in: html) else { return nil }
            return String(html[r])
        }
    }

    func extractFirstByRegex(_ html: String, pattern: String) -> String? {
        extractByRegex(html, pattern: pattern).first
    }

    // MARK: - CSS 选择器（增强版）

    func extractByCSSSelector(_ html: String, selector: String) -> [String] {
        let trimmed = selector.trimmingCharacters(in: .whitespaces)

        // 解析 selector 中的属性提取后缀 @attr
        var attrName: String? = nil
        var pureSelector = trimmed
        if let atIdx = trimmed.range(of: "@", options: .backwards) {
            let after = String(trimmed[atIdx.upperBound...])
            if !after.contains(" ") && !after.contains(".") && !after.contains("#") {
                attrName = after == "text" || after == "ownText" ? nil : after
                pureSelector = String(trimmed[..<atIdx.lowerBound])
                if after == "text" || after == "ownText" { attrName = "__text__" }
            }
        }

        var results = extractBySelector(html, selector: pureSelector)

        // 后处理：提取属性或文本
        if let attr = attrName {
            if attr == "__text__" {
                results = results.map { StringUtils.shared.stripHTML($0) }
            } else {
                results = results.compactMap { frag -> String? in
                    let pattern = "\(attr)=[\"']([^\"']+)[\"']"
                    return extractFirstByRegex(frag, pattern: pattern)
                }
            }
        }
        return results
    }

    private func extractBySelector(_ html: String, selector: String) -> [String] {
        let s = selector.trimmingCharacters(in: .whitespaces)
        if s.isEmpty { return [html] }

        // 支持 "tag.class > child" 逐级提取
        let parts = s.components(separatedBy: ">").map { $0.trimmingCharacters(in: .whitespaces) }
        var current = [html]
        for part in parts {
            current = current.flatMap { extractSingleLevel($0, part: part) }
        }
        return current
    }

    private func extractSingleLevel(_ html: String, part: String) -> [String] {
        var tag = part
        var classFilter: String? = nil
        var idFilter: String? = nil
        var attrFilter: (key: String, val: String)? = nil

        // 解析 tag#id.class[attr=val]
        if let hashIdx = tag.firstIndex(of: "#") {
            let rest = String(tag[tag.index(after: hashIdx)...])
            tag = String(tag[..<hashIdx])
            idFilter = rest.components(separatedBy: ".").first
        }
        if let dotIdx = tag.firstIndex(of: ".") {
            classFilter = String(tag[tag.index(after: dotIdx)...])
            tag = String(tag[..<dotIdx])
        }
        if tag.contains("["), let start = tag.firstIndex(of: "["), let end = tag.firstIndex(of: "]") {
            let attrStr = String(tag[tag.index(after: start)..<end])
            let kv = attrStr.components(separatedBy: "=")
            if kv.count == 2 {
                attrFilter = (kv[0].trimmingCharacters(in: .whitespaces),
                              kv[1].trimmingCharacters(in: .init(charactersIn: "\"' ")))
            }
            tag = String(tag[..<start])
        }

        let tagName = tag.isEmpty ? "[a-zA-Z][a-zA-Z0-9]*" : NSRegularExpression.escapedPattern(for: tag)

        // 构造正则
        var attrPattern = ""
        if let id = idFilter { attrPattern += "(?=[^>]*id=[\"']\(NSRegularExpression.escapedPattern(for: id))[\"'])" }
        if let cls = classFilter { attrPattern += "(?=[^>]*class=[\"'][^\"']*\\b\(NSRegularExpression.escapedPattern(for: cls))\\b)" }
        if let av = attrFilter { attrPattern += "(?=[^>]*\(av.key)=[\"']\(NSRegularExpression.escapedPattern(for: av.val))[\"'])" }

        let pattern = "<(\(tagName))\(attrPattern)[^>]*>([\\s\\S]*?)</\\1>"
        return extractByRegex(html, pattern: pattern)
    }

    // MARK: - 链接与图片

    func extractLinks(_ html: String) -> [(title: String, url: String)] {
        let pattern = "<a[^>]*href=[\"']([^\"']+)[\"'][^>]*>([^<]*)</a>"
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        return re.matches(in: html, range: range).compactMap { m -> (String, String)? in
            guard let ur = Range(m.range(at: 1), in: html),
                  let tr = Range(m.range(at: 2), in: html) else { return nil }
            return (String(html[tr]), String(html[ur]))
        }
    }

    func extractImages(_ html: String) -> [String] {
        extractByRegex(html, pattern: "<img[^>]+src=[\"']([^\"']+)[\"']")
    }

    // MARK: - JSON-LD

    func extractJSONLD(_ html: String) -> [[String: Any]] {
        let strs = extractByRegex(html, pattern: "<script[^>]+type=[\"']application/ld\\+json[\"'][^>]*>([\\s\\S]*?)</script>")
        return strs.compactMap { s -> [String: Any]? in
            guard let d = s.data(using: .utf8) else { return nil }
            return try? JSONSerialization.jsonObject(with: d) as? [String: Any]
        }
    }

    // MARK: - 标签间内容

    func extractBetween(_ html: String, startTag: String, endTag: String) -> [String] {
        let pattern = NSRegularExpression.escapedPattern(for: startTag)
            + "([\\s\\S]*?)"
            + NSRegularExpression.escapedPattern(for: endTag)
        return extractByRegex(html, pattern: pattern)
    }
}
