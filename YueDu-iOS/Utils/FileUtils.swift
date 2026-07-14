import Foundation

/// 文件操作工具类
class FileUtils {
    static let shared = FileUtils()
    
    private let fileManager = FileManager.default
    
    /// 获取文档目录路径
    var documentsDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    /// 获取缓存目录路径
    var cachesDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    /// 创建目录
    func createDirectory(_ path: String) -> Bool {
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            return true
        } catch {
            print("❌ 创建目录失败: \(error)")
            return false
        }
    }
    
    /// 创建目录（URL）
    func createDirectory(_ url: URL) -> Bool {
        return createDirectory(url.path)
    }
    
    /// 检查文件是否存在
    func fileExists(_ path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    /// 删除文件
    func deleteFile(_ path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            print("❌ 删除文件失败: \(error)")
            return false
        }
    }
    
    /// 保存字符串到文件
    func saveString(_ content: String, to path: String) -> Bool {
        do {
            // 创建父目录
            let parentPath = (path as NSString).deletingLastPathComponent
            try fileManager.createDirectory(atPath: parentPath, withIntermediateDirectories: true)
            
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("❌ 保存文件失败: \(error)")
            return false
        }
    }
    
    /// 读取文件内容
    func readString(from path: String) -> String? {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            print("❌ 读取文件失败: \(error)")
            return nil
        }
    }
    
    /// 保存数据到文件
    func saveData(_ data: Data, to path: String) -> Bool {
        do {
            // 创建父目录
            let parentPath = (path as NSString).deletingLastPathComponent
            try fileManager.createDirectory(atPath: parentPath, withIntermediateDirectories: true)
            
            try data.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            print("❌ 保存数据失败: \(error)")
            return false
        }
    }
    
    /// 读取数据
    func readData(from path: String) -> Data? {
        return fileManager.contents(atPath: path)
    }
    
    /// 保存 JSON 对象
    func saveJSON<T: Encodable>(_ object: T, to path: String) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(object)
            return saveData(data, to: path)
        } catch {
            print("❌ 保存 JSON 失败: \(error)")
            return false
        }
    }
    
    /// 读取 JSON 对象
    func readJSON<T: Decodable>(from path: String, type: T.Type) -> T? {
        guard let data = readData(from: path) else { return nil }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            print("❌ 读取 JSON 失���: \(error)")
            return nil
        }
    }
    
    /// 获取文件大小
    func fileSize(_ path: String) -> Int64? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    /// 获取文件修改时间
    func modificationDate(_ path: String) -> Date? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    /// 清空缓存目录
    func clearCaches() -> Bool {
        do {
            let files = try fileManager.contentsOfDirectory(atPath: cachesDirectory.path)
            for file in files {
                let path = cachesDirectory.appendingPathComponent(file).path
                try fileManager.removeItem(atPath: path)
            }
            return true
        } catch {
            print("❌ 清空缓存失败: \(error)")
            return false
        }
    }
}
