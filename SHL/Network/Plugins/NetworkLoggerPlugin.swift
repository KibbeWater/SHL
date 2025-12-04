//
//  NetworkLoggerPlugin.swift
//  SHL
//
//  Created by Migration Script
//

import Foundation
import Moya

final class NetworkLoggerPlugin: PluginType {
    private let verbose: Bool

    init(verbose: Bool = false) {
        self.verbose = verbose
    }

    func willSend(_ request: RequestType, target: TargetType) {
        guard verbose else { return }

        if let request = request.request {
            print("🌐 [REQUEST] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
            if let headers = request.allHTTPHeaderFields {
                print("📋 [HEADERS] \(headers)")
            }
            if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                print("📦 [BODY] \(bodyString)")
            }
        }
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        guard verbose else { return }

        switch result {
        case .success(let response):
            print("✅ [RESPONSE] \(response.statusCode) from \(response.request?.url?.absoluteString ?? "")")
            if let jsonObject = try? response.mapJSON(),
               let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: data, encoding: .utf8) {
                print("📄 [DATA] \(prettyString)")
            }

        case .failure(let error):
            print("❌ [ERROR] \(error.localizedDescription)")
            if let response = error.response {
                print("⚠️ [STATUS] \(response.statusCode)")
                if let data = try? response.mapString() {
                    print("📄 [DATA] \(data)")
                }
            }
        }
    }
}
