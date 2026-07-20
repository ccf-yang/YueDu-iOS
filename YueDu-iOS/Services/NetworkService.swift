import Foundation

/// 网络请求服务
class NetworkService {
    static let shared = NetworkService()
    private let session: URLSession

    private let defaultHeaders: [String: String] = [
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.9",
        "Accept-Encoding": "gzip, deflate"
    ]

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    /// GET 请求，返回 HTML 字符串（自动处理 GBK/UTF-8 编码）
    func get(url: String, headers: [String: String]? = nil) async throws -> String {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw NetworkError.httpError(statusCode: http.statusCode) }

        // 优先检测 charset 声明
        if let detected = detectEncoding(from: data, contentType: http.value(forHTTPHeaderField: "Content-Type")) {
            if let str = String(data: data, encoding: detected) { return str }
        }
        if let str = String(data: data, encoding: .utf8) { return str }
        if let str = String(data: data, encoding: .gbk) { return str }
        if let str = String(data: data, encoding: .isoLatin1) { return str }
        throw NetworkError.decodingError
    }

    /// GET 请求，返回 Data
    func getData(url: String, headers: [String: String]? = nil) async throws -> Data {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else { throw NetworkError.invalidResponse }
        return data
    }

    /// POST 请求
    func post(url: String, body: [String: Any]?, headers: [String: String]? = nil) async throws -> Data {
        guard let url = URL(string: url) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        if let body = body {
            let bodyStr = body.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = bodyStr.data(using: .utf8)
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else { throw NetworkError.invalidResponse }
        return data
    }

    /// 构建带变量替换的搜索 URL
    func buildSearchURL(template: String, keyword: String) -> String {
        var url = template
        let encoded = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
        url = url.replacingOccurrences(of: "{{key}}", with: encoded)
        url = url.replacingOccurrences(of: "{key}", with: encoded)
        url = url.replacingOccurrences(of: "searchKey", with: encoded)
        return url
    }

    /// 解析响应中的编码
    private func detectEncoding(from data: Data, contentType: String?) -> String.Encoding? {
        // 从 Content-Type 头解析
        if let ct = contentType?.lowercased() {
            if ct.contains("gbk") || ct.contains("gb2312") || ct.contains("gb18030") { return .gbk }
            if ct.contains("utf-8") { return .utf8 }
        }
        // 从 HTML meta 标签解析（检查前 1024 字节）
        let previewData = data.prefix(1024)
        if let preview = String(data: previewData, encoding: .ascii) {
            if preview.lowercased().contains("gbk") || preview.lowercased().contains("gb2312") { return .gbk }
        }
        return nil
    }
}

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case timeout
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .invalidResponse: return "无效的响应"
        case .httpError(let code): return "HTTP 错误: \(code)"
        case .decodingError: return "解码失败"
        case .timeout: return "请求超时"
        case .unknown(let msg): return msg
        }
    }
}

extension String.Encoding {
    static let gbk: String.Encoding = {
        let cfEnc = CFStringEncodings.GB_18030_2000
        let ns = CFStringConvertEncodingToNS(CFStringEncoding(cfEnc.rawValue))
        return String.Encoding(rawValue: ns.unsignedLongValue)
    }()
}
