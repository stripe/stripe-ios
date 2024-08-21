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
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        return try JSONDecoder().decode(DecodableType.self, from: jsonData)
    }
}
