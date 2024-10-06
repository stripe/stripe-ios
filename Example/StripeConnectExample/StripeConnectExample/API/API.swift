//
//  API.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/23/24.
//

import Foundation

struct API {
    static func appInfo(baseURL: String = AppSettings.shared.selectedServerBaseURL) async -> Result<AppInfo, APIError> {
        await apiRequest(path: "app_info", baseURL: baseURL)
    }

    static func accountSession(merchantId: String? = nil, baseURL: String = AppSettings.shared.selectedServerBaseURL) async -> Result<AccountSessionResponse, APIError> {
        await apiRequest(path: "account_session",
                         method: "POST",
                         headers: merchantId.map { ["account": $0] } ?? [:],
                         baseURL: baseURL)
    }

    static func apiRequest<Response: Codable>(path: String,
                                              method: String = "GET",
                                              headers: [String: String] = [:],
                                              baseURL: String = AppSettings.shared.selectedServerBaseURL) async -> Result<Response, APIError> {
        guard let baseUrl = URL(string: baseURL) else {
            return .failure(.invalidURL)
        }
        let url = baseUrl.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let (data, response)  = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                do {
                    return .failure(.responseError(response: try decoder.decode(APIErrorResponse.self, from: data)))
                } catch {
                    return .failure(.failedToParse(error: error))
                }
            }
            do {
                return .success(try decoder.decode(Response.self, from: data))
            } catch {
                return .failure(.failedToParse(error: error))
            }
        } catch {
            return .failure(.networkError(error: error))
        }
    }
}
