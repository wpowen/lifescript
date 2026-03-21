import Foundation

enum AppError: LocalizedError {
    case network(underlying: Error)
    case decoding(underlying: Error)
    case server(statusCode: Int, message: String)
    case contentNotFound(String)
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .network:
            return String(localized: "网络连接失败，请检查网络后重试")
        case .decoding:
            return String(localized: "数据解析出错，请更新应用")
        case .server(_, let msg):
            return msg
        case .contentNotFound(let id):
            return String(localized: "内容未找到: \(id)")
        case .unauthorized:
            return String(localized: "请先登录")
        case .unknown:
            return String(localized: "发生了未知错误")
        }
    }

    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        if let contentError = error as? ContentError {
            return .contentNotFound(contentError.localizedDescription)
        }
        if (error as NSError).domain == NSURLErrorDomain {
            return .network(underlying: error)
        }
        if error is DecodingError { return .decoding(underlying: error) }
        return .unknown
    }
}
