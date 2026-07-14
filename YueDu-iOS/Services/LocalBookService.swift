import Foundation

/// 本地书籍服务 - 支持 TXT 等本地文件格式
class LocalBookService {
    static let shared = LocalBookService()
    
    private let fileUtils = FileUtils.shared
    private let db = DatabaseService.shared
    
    /// 导入 TXT 文件
    func importTXTFile(_ filePath: String) -> Book? {
        guard let content = fileUtils.readString(from: filePath) else {
            return nil
        }
        
        let fileName = (filePath as NSString).lastPathComponent
        let bookName = (fileName as NSString).deletingPathExtension
        
        // 自动分章
        let chapters = autoChapters(content)
        
        let book = Book(
            id: filePath,
            name: bookName,
            author: "未知",
            origin: "local",
            originName: "本地",
            type: 0,
            totalChapterNum: chapters.count
        )
        
        // 保存书籍
        _ = db.saveBook(book)
        
        // 保存章节
        for chapter in chapters {
            _ = db.saveChapter(chapter)
        }
        
        return book
    }
    
    /// 自动分章
    private func autoChapters(_ content: String) -> [BookChapter] {
        var chapters: [BookChapter] = []
        
        // 按照常见的章节标记分割
        let patterns = [
            "(?:第[0-9一二三四五六七八九十百千万]+[章回])",  // 第一章
            "(?:^\\s*[0-9]+\\s*$)",  // 纯数字行
            "(?:^\\s*第[0-9]+节\\s*$)"  // 第1节
        ]
        
        var lines = content.components(separatedBy: "\n")
        var currentChapter = ""
        var chapterIndex = 0
        var chapterStart: Int64 = 0
        
        for (lineIndex, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 检查是否是章节标题
            var isChapterTitle = false
            for pattern in patterns {
                if trimmedLine.range(of: pattern, options: .regularExpression) != nil {
                    isChapterTitle = true
                    break
                }
            }
            
            if isChapterTitle && !currentChapter.isEmpty {
                // 保存前一章
                let chapter = BookChapter(
                    url: "",
                    title: extractChapterTitle(currentChapter) ?? "第 \(chapterIndex) 章",
                    bookUrl: "",
                    index: chapterIndex,
                    baseUrl: "",
                    start: chapterStart,
                    end: chapterStart + Int64(currentChapter.count)
                )
                chapters.append(chapter)
                
                currentChapter = trimmedLine
                chapterStart += Int64(currentChapter.count)
                chapterIndex += 1
            } else {
                currentChapter += line + "\n"
            }
        }
        
        // 保存最后一章
        if !currentChapter.isEmpty {
            let chapter = BookChapter(
                url: "",
                title: extractChapterTitle(currentChapter) ?? "第 \(chapterIndex) 章",
                bookUrl: "",
                index: chapterIndex,
                baseUrl: "",
                start: chapterStart,
                end: chapterStart + Int64(currentChapter.count)
            )
            chapters.append(chapter)
        }
        
        return chapters
    }
    
    /// 提取章节标题
    private func extractChapterTitle(_ content: String) -> String? {
        let lines = content.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && trimmed.count < 100 {
                return trimmed
            }
        }
        return nil
    }
    
    /// 读取本地章节内容
    func readLocalChapterContent(_ book: Book, chapterIndex: Int) -> String? {
        guard let content = fileUtils.readString(from: book.id) else {
            return nil
        }
        
        let chapters = autoChapters(content)
        guard chapterIndex < chapters.count else {
            return nil
        }
        
        let chapter = chapters[chapterIndex]
        let startIndex = content.index(content.startIndex, offsetBy: Int(chapter.start ?? 0))
        let endIndex = content.index(content.startIndex, offsetBy: Int(chapter.end ?? Int64(content.count)))
        
        return String(content[startIndex..<endIndex])
    }
}
