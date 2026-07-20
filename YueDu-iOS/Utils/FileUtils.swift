import Foundation

class FileUtils {
    static let shared = FileUtils()
    private let fm = FileManager.default

    var documentsDirectory: URL { fm.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    var cachesDirectory: URL    { fm.urls(for: .cachesDirectory,   in: .userDomainMask)[0] }

    @discardableResult
    func createDirectory(_ url: URL) -> Bool {
        do { try fm.createDirectory(at: url, withIntermediateDirectories: true); return true }
        catch { print("❌ createDir: \(error)"); return false }
    }

    func fileExists(_ path: String) -> Bool { fm.fileExists(atPath: path) }

    @discardableResult
    func delete(_ url: URL) -> Bool {
        do { try fm.removeItem(at: url); return true }
        catch { print("❌ delete: \(error)"); return false }
    }

    @discardableResult
    func saveString(_ s: String, to path: String) -> Bool {
        do {
            try fm.createDirectory(atPath: (path as NSString).deletingLastPathComponent,
                                   withIntermediateDirectories: true)
            try s.write(toFile: path, atomically: true, encoding: .utf8)
            return true
        } catch { print("❌ saveString: \(error)"); return false }
    }

    func readString(from path: String) -> String? {
        try? String(contentsOfFile: path, encoding: .utf8)
    }

    @discardableResult
    func saveData(_ data: Data, to url: URL) -> Bool {
        do {
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
            return true
        } catch { print("❌ saveData: \(error)"); return false }
    }

    func readData(from url: URL) -> Data? { fm.contents(atPath: url.path) }

    func saveJSON<T: Encodable>(_ obj: T, to path: String) -> Bool {
        guard let data = try? JSONEncoder().encode(obj) else { return false }
        return saveString(String(data: data, encoding: .utf8) ?? "", to: path)
    }

    func readJSON<T: Decodable>(from path: String, type: T.Type) -> T? {
        guard let data = fm.contents(atPath: path) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func fileSize(_ url: URL) -> Int64 {
        (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map { Int64($0) } ?? 0
    }

    func formattedSize(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        return String(format: "%.1f GB", mb / 1024)
    }

    @discardableResult
    func clearCaches() -> Bool {
        guard let files = try? fm.contentsOfDirectory(at: cachesDirectory,
                                                      includingPropertiesForKeys: nil) else { return false }
        files.forEach { try? fm.removeItem(at: $0) }
        return true
    }
}
