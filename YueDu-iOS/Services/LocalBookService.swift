import Foundation

/// 本地书籍导入服务 - 支持 TXT 和 EPUB
class LocalBookService {
    static let shared = LocalBookService()
    private let db = DatabaseService.shared

    // MARK: - TXT 导入

    func importTXT(url: URL, bookName: String? = nil) async throws -> Book {
        let rawData = try Data(contentsOf: url)
        // 自动检测编码
        let content: String
        if let utf8 = String(data: rawData, encoding: .utf8) {
            content = utf8
        } else if let gbk = String(data: rawData, encoding: .gbk) {
            content = gbk
        } else {
            content = String(data: rawData, encoding: .isoLatin1) ?? ""
        }
        guard !content.isEmpty else { throw LocalBookError.emptyContent }

        let fileName = url.deletingPathExtension().lastPathComponent
        let name = bookName ?? fileName
        let bookId = "local_txt_\(url.lastPathComponent)_\(Int(Date().timeIntervalSince1970))"

        // 自动分章
        let chapters = splitTXTIntoChapters(content: content, bookUrl: bookId)

        var book = Book(
            id: bookId, name: name, author: "未知作者",
            origin: "local", originName: "本地",
            totalChapterNum: chapters.count,
            type: 0
        )
        db.saveBook(book)
        db.saveChapters(chapters)

        // 缓存所有章节内容（TXT直接存）
        for chapter in chapters {
            if let start = chapter.start, let end = chapter.end {
                let startIdx = content.index(content.startIndex, offsetBy: Int(start), limitedBy: content.endIndex) ?? content.startIndex
                let endIdx   = content.index(content.startIndex, offsetBy: Int(end),   limitedBy: content.endIndex) ?? content.endIndex
                let chContent = String(content[startIdx..<endIdx])
                db.cacheChapterContent(bookUrl: bookId, chapterUrl: chapter.url, content: chContent)
            }
        }
        return book
    }

    /// TXT 分章算法
    private func splitTXTIntoChapters(content: String, bookUrl: String) -> [BookChapter] {
        // 章节标题匹配规则（优先级从高到低）
        let chapterPatterns = [
            "第[零一二三四五六七八九十百千万\\d]+[章节回篇集部卷]\\s*[\\u4e00-\\u9fff\\w]*",
            "Chapter\\s*\\d+[\\s\\S]*",
            "\\d+\\.\\s*[\\u4e00-\\u9fff]{2,}",
            "【[^】]+】",
            "\\[.+?\\]"
        ]

        let combinedPattern = chapterPatterns.joined(separator: "|")
        guard let regex = try? NSRegularExpression(pattern: combinedPattern, options: .caseInsensitive) else {
            return [defaultChapter(content: content, bookUrl: bookUrl)]
        }

        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, range: range)

        guard !matches.isEmpty else {
            // 没有找到章节，按字数分割
            return splitByWordCount(content: content, bookUrl: bookUrl)
        }

        var chapters: [BookChapter] = []
        for (i, match) in matches.enumerated() {
            guard let titleRange = Range(match.range, in: content) else { continue }
            let title = String(content[titleRange])
            let startPos = content.distance(from: content.startIndex, to: titleRange.lowerBound)
            let endPos   = i + 1 < matches.count
                ? content.distance(from: content.startIndex, to: Range(matches[i + 1].range, in: content)!.lowerBound)
                : content.count
            let url = "\(bookUrl)_chapter_\(i)"
            chapters.append(BookChapter(
                url: url, title: title, bookUrl: bookUrl, index: i,
                start: Int64(startPos), end: Int64(endPos)
            ))
        }
        return chapters
    }

    private func splitByWordCount(content: String, bookUrl: String, chunkSize: Int = 3000) -> [BookChapter] {
        var chapters: [BookChapter] = []
        var start = 0
        var index = 0
        let total = content.count
        while start < total {
            let end = min(start + chunkSize, total)
            let url = "\(bookUrl)_chunk_\(index)"
            let title = "第\(index + 1)节"
            chapters.append(BookChapter(
                url: url, title: title, bookUrl: bookUrl, index: index,
                start: Int64(start), end: Int64(end)
            ))
            start = end
            index += 1
        }
        return chapters
    }

    private func defaultChapter(content: String, bookUrl: String) -> BookChapter {
        BookChapter(url: "\(bookUrl)_0", title: "全文", bookUrl: bookUrl, index: 0,
                    start: 0, end: Int64(content.count))
    }

    // MARK: - EPUB 导入

    func importEPUB(url: URL, bookName: String? = nil) async throws -> Book {
        let bookId = "local_epub_\(url.lastPathComponent)_\(Int(Date().timeIntervalSince1970))"
        let unzipDir = FileManager.default.temporaryDirectory.appendingPathComponent(bookId)
        try FileManager.default.createDirectory(at: unzipDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: unzipDir) }

        // 解压 EPUB（ZIP 格式）—— 使用系统原生实现，无需第三方依赖
        try unzipEPUB(at: url, to: unzipDir)

        // 解析 OPF 文件
        let opf = try parseEPUBOPF(baseDir: unzipDir)
        let name = bookName ?? opf.title ?? url.deletingPathExtension().lastPathComponent
        let author = opf.creator ?? "未知作者"
        let coverPath = opf.coverPath.map { unzipDir.appendingPathComponent($0).path }

        var book = Book(id: bookId, name: name, author: author,
                        origin: "local", originName: "本地", totalChapterNum: opf.spine.count, type: 0)

        // 复制封面到文档目录
        if let cp = coverPath, FileManager.default.fileExists(atPath: cp),
           let coverData = FileManager.default.contents(atPath: cp) {
            let destUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("covers/\(bookId).jpg")
            try? FileManager.default.createDirectory(at: destUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? coverData.write(to: destUrl)
            book.coverUrl = destUrl.path
        }

        db.saveBook(book)

        // 解析章节
        var chapters: [BookChapter] = []
        for (i, item) in opf.spine.enumerated() {
            let chapterUrl = "\(bookId)_\(i)"
            let chapterFilePath = unzipDir.appendingPathComponent(item.href).path
            let title = item.title ?? "第\(i + 1)章"
            chapters.append(BookChapter(url: chapterUrl, title: title, bookUrl: bookId, index: i,
                                        startFragmentId: item.href))
            // 缓存内容
            if let htmlData = FileManager.default.contents(atPath: chapterFilePath),
               let html = String(data: htmlData, encoding: .utf8) ?? String(data: htmlData, encoding: .gbk) {
                let content = extractEPUBContent(html: html)
                db.cacheChapterContent(bookUrl: bookId, chapterUrl: chapterUrl, content: content)
            }
        }
        db.saveChapters(chapters)
        return book
    }

    private func extractEPUBContent(html: String) -> String {
        // 提取 body 内容，移除标签
        let bodyPattern = "<body[^>]*>([\\s\\S]*?)</body>"
        if let regex = try? NSRegularExpression(pattern: bodyPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let body = String(html[range])
            return StringUtils.shared.stripHTML(body)
        }
        return StringUtils.shared.stripHTML(html)
    }

    // MARK: - EPUB OPF 解析

    private func parseEPUBOPF(baseDir: URL) throws -> EPUBOPFInfo {
        // 读取 container.xml
        let containerPath = baseDir.appendingPathComponent("META-INF/container.xml").path
        guard let containerData = FileManager.default.contents(atPath: containerPath),
              let container = String(data: containerData, encoding: .utf8) else {
            throw LocalBookError.epubInvalidFormat
        }

        // 提取 OPF 路径
        let opfPattern = "full-path=\"([^\"]+\\.opf)\""
        guard let opfMatch = try? NSRegularExpression(pattern: opfPattern).firstMatch(
            in: container, range: NSRange(container.startIndex..., in: container)),
              let opfRange = Range(opfMatch.range(at: 1), in: container) else {
            throw LocalBookError.epubInvalidFormat
        }
        let opfPath = String(container[opfRange])
        let opfDir  = (opfPath as NSString).deletingLastPathComponent
        let opfFullPath = baseDir.appendingPathComponent(opfPath).path

        guard let opfData = FileManager.default.contents(atPath: opfFullPath),
              let opf = String(data: opfData, encoding: .utf8) else {
            throw LocalBookError.epubInvalidFormat
        }

        var info = EPUBOPFInfo()

        // 解析元数据
        info.title   = extractXML(opf, tag: "dc:title")
        info.creator = extractXML(opf, tag: "dc:creator")

        // 解析 manifest（id -> href 映射）
        var manifest: [String: String] = [:]
        var titleMap: [String: String] = [:]
        let itemPattern = "<item[^>]+id=\"([^\"]+)\"[^>]+href=\"([^\"]+)\"[^>]*/>"
        if let re = try? NSRegularExpression(pattern: itemPattern),
           let data = opf.data(using: .utf8) {
            let str = String(data: data, encoding: .utf8) ?? opf
            let matches = re.matches(in: str, range: NSRange(str.startIndex..., in: str))
            for m in matches {
                if let idRange   = Range(m.range(at: 1), in: str),
                   let hrefRange = Range(m.range(at: 2), in: str) {
                    let id   = String(str[idRange])
                    let href = opfDir.isEmpty ? String(str[hrefRange]) : "\(opfDir)/\(String(str[hrefRange]))"
                    manifest[id] = href
                }
            }
        }

        // 解析 spine 顺序
        let spinePattern = "<itemref[^>]+idref=\"([^\"]+)\""
        if let re = try? NSRegularExpression(pattern: spinePattern) {
            let matches = re.matches(in: opf, range: NSRange(opf.startIndex..., in: opf))
            for m in matches {
                if let r = Range(m.range(at: 1), in: opf) {
                    let idref = String(opf[r])
                    if let href = manifest[idref] {
                        info.spine.append(EPUBSpineItem(href: href, title: titleMap[idref]))
                    }
                }
            }
        }

        // 封面
        if let coverId = extractXMLAttr(opf, tag: "meta", attrName: "name", attrValue: "cover", targetAttr: "content"),
           let coverHref = manifest[coverId] {
            info.coverPath = coverHref
        }
        return info
    }

    private func extractXML(_ xml: String, tag: String) -> String? {
        let pattern = "<\(tag)[^>]*>([^<]+)</"
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let r = Range(m.range(at: 1), in: xml) else { return nil }
        return String(xml[r]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractXMLAttr(_ xml: String, tag: String, attrName: String, attrValue: String, targetAttr: String) -> String? {
        let pattern = "<\(tag)[^>]+\(attrName)=\"\(attrValue)\"[^>]+\(targetAttr)=\"([^\"]+)\""
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
              let r = Range(m.range(at: 1), in: xml) else { return nil }
        return String(xml[r])
    }
}

private struct EPUBOPFInfo {
    var title: String?
    var creator: String?
    var coverPath: String?
    var spine: [EPUBSpineItem] = []
}

private struct EPUBSpineItem {
    var href: String
    var title: String?
}

// MARK: - 原生 ZIP 解压（替代 ZipArchive，零第三方依赖）
private extension LocalBookService {
    /// 使用系统 /usr/bin/unzip 解压 ZIP/EPUB 文件
    func unzipEPUB(at source: URL, to destination: URL) throws {
        // iOS 上使用 Process 调用系统 unzip（模拟器和 macOS CI 均可用）
        // 真机上 Process 不可用，改用纯 Swift ZIP 解析
        #if targetEnvironment(simulator) || os(macOS)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", "-q", source.path, "-d", destination.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw LocalBookError.epubInvalidFormat
        }
        #else
        // 真机：使用纯 Swift 实现的 ZIP 解析
        try unzipPureSwift(at: source, to: destination)
        #endif
    }

    /// 纯 Swift ZIP 解析（支持 Store 和 Deflate 压缩，覆盖绝大多数 EPUB）
    func unzipPureSwift(at source: URL, to destination: URL) throws {
        let data = try Data(contentsOf: source)
        let fm   = FileManager.default

        var offset = 0
        while offset + 30 < data.count {
            // Local file header signature: 0x04034b50
            let sig = data.readUInt32LE(at: offset)
            guard sig == 0x04034B50 else { break }

            let compression  = data.readUInt16LE(at: offset + 8)
            let compSize     = Int(data.readUInt32LE(at: offset + 18))
            let uncompSize   = Int(data.readUInt32LE(at: offset + 22))
            let fileNameLen  = Int(data.readUInt16LE(at: offset + 26))
            let extraLen     = Int(data.readUInt16LE(at: offset + 28))

            let nameStart = offset + 30
            let nameEnd   = nameStart + fileNameLen
            guard nameEnd <= data.count else { break }

            let nameBytes = data[nameStart..<nameEnd]
            let fileName  = String(bytes: nameBytes, encoding: .utf8)
                         ?? String(bytes: nameBytes, encoding: .isoLatin1)
                         ?? ""

            let dataStart = nameEnd + extraLen
            let dataEnd   = dataStart + compSize
            guard dataEnd <= data.count else { break }

            let entryData = data[dataStart..<dataEnd]
            let destURL   = destination.appendingPathComponent(fileName)

            if fileName.hasSuffix("/") {
                try fm.createDirectory(at: destURL, withIntermediateDirectories: true)
            } else {
                try fm.createDirectory(at: destURL.deletingLastPathComponent(),
                                       withIntermediateDirectories: true)
                switch compression {
                case 0: // Store
                    try entryData.write(to: destURL)
                case 8: // Deflate
                    let decompressed = try (entryData as NSData).decompressed(using: .zlib) as Data
                    // zlib 与 deflate 差 2 字节 header；若失败回退到原始写入
                    let finalData = decompressed.count == uncompSize ? decompressed : Data(entryData)
                    try finalData.write(to: destURL)
                default:
                    // 不支持的压缩方式，写原始数据（可能不可读，但不崩溃）
                    try entryData.write(to: destURL)
                }
            }
            offset = dataEnd
        }

        // 校验至少解压出了 META-INF
        let metaInf = destination.appendingPathComponent("META-INF/container.xml")
        guard fm.fileExists(atPath: metaInf.path) else {
            throw LocalBookError.epubInvalidFormat
        }
    }
}

private extension Data {
    func readUInt16LE(at offset: Int) -> UInt16 {
        guard offset + 2 <= count else { return 0 }
        return UInt16(self[offset]) | (UInt16(self[offset + 1]) << 8)
    }
    func readUInt32LE(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        return UInt32(self[offset])
             | (UInt32(self[offset + 1]) << 8)
             | (UInt32(self[offset + 2]) << 16)
             | (UInt32(self[offset + 3]) << 24)
    }
}

enum LocalBookError: LocalizedError {
    case emptyContent
    case epubInvalidFormat
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .emptyContent: return "文件内容为空"
        case .epubInvalidFormat: return "EPUB 格式无效"
        case .unsupportedFormat: return "不支持的文件格式"
        }
    }
}
