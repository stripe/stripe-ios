//
//  APIClient.swift
//  CardImageVerification Example
//
//  Created by Jaime Park on 11/28/21.
//

import Foundation

struct APIClient {
    static func jsonRequest(
        url: URL,
        requestJson: [String: Any],
        httpMethod: String,
        completion: @escaping (Data?) -> Void
    ) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: requestJson, options: [])
        urlRequest.httpMethod = httpMethod
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                guard
                    error == nil,
                    let data = data
                else {
                    completion(nil)
                    return
                }

                completion(data)
             }
        }.resume()
    }
}
