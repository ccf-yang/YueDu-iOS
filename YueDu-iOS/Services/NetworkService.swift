import Foundation

/// 网络服务 - 管理 HTTP 请求
class NetworkService {
    static let shared = NetworkService()
    
    private let session: URLSession
    private let timeout: TimeInterval = 30
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    /// 获取网页内容
    func fetchHTML(url: String, headers: [String: String]? = nil) async throws -> String {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 设置默认请求头
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        
        // 添加自定义请求头
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // 尝试多种编码
        if let html = String(data: data, encoding: .utf8) {
            return html
        } else if let html = String(data: data, encoding: .gbk) {
            return html
        } else {
            throw NetworkError.decodingError
        }
    }
    
    /// 发送 POST 请求
    func post(
        url: String,
        body: [String: Any]?,
        headers: [String: String]? = nil
    ) async throws -> Data {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 设置默认请求头
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加自定义请求头
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // 设置请求体
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return data
    }
    
    /// 下载图片
    func downloadImage(url: String) async throws -> Data {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return data
    }
}

// MARK: - 错误定义
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let statusCode):
            return "HTTP 错误: \(statusCode)"
        case .decodingError:
            return "解码失败"
        case .timeout:
            return "请求超时"
        case .unknown:
            return "未知错误"
        }
    }
}

// MARK: - GBK 编码支持
extension String.Encoding {
    static let gbk: String.Encoding = {
        let cfEncoding = CFStringEncodings.GB_18030_2000
        return String.Encoding(rawValue: CFStringConvertEncodingToNS(CFStringEncoding(cfEncoding.rawValue)).unsignedLongValue)
    }()
}
