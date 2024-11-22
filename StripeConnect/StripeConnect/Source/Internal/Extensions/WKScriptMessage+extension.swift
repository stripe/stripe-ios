//
//  WKScriptMessage+extension.swift
//  StripeConnect
//
//  Created by Chris Mays on 8/22/24.
//

import WebKit

extension WKScriptMessage {
    func toDecodable<DecodableType: Decodable>() throws -> DecodableType {
        if let payload = body as? DecodableType {
            return payload
        }
        let jsonData = try toData()
        return try JSONDecoder().decode(DecodableType.self, from: jsonData)
    }

    func toData() throws -> Data {
        if let bodyString = body as? String,
            let data = bodyString.data(using: .utf8) {
            return data
        }
        return try JSONSerialization.connectData(withJSONObject: body)
    }
}
