//
//  SHLAPIError.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation

enum SHLAPIError: Error, LocalizedError {
    case networkError(underlying: Error)
    case decodingError(underlying: Error)
    case invalidResponse
    case invalidURL
    case httpError(statusCode: Int, data: Data?)
    case notFound
    case serverError
    case unauthorized
    case unknown

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidURL:
            return "Invalid URL"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error occurred"
        case .unauthorized:
            return "Unauthorized access"
        case .unknown:
            return "An unknown error occurred"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .serverError:
            return true
        case .httpError(let code, _):
            return code >= 500 && code < 600
        default:
            return false
        }
    }
}

extension SHLAPIError {
    static func map(statusCode: Int, data: Data?) -> SHLAPIError {
        switch statusCode {
        case 200..<300:
            return .unknown
        case 401:
            return .unauthorized
        case 404:
            return .notFound
        case 500..<600:
            return .serverError
        default:
            return .httpError(statusCode: statusCode, data: data)
        }
    }
}
