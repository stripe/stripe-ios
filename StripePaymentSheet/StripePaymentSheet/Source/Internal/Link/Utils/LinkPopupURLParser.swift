//
//  LinkPopupURLParser.swift
//  StripePaymentSheet
//

import Foundation
import StripePayments

enum LinkResult {
    case complete(STPPaymentMethod)
    case logout
}

class LinkPopupURLParser {
    static func result(with resultURL: URL) throws -> LinkResult {
        let components = URLComponents(url: resultURL, resolvingAgainstBaseURL: false)
        guard let status = components?.queryItems?.first(where: { $0.name == "link_status" })?.value else {
            throw LinkPopupURLParserError.invalidURLParams
        }
        switch status {
        case "complete":
            guard let pmItem = components?.queryItems?.first(where: { $0.name == "pm" })?.value else {
                throw LinkPopupURLParserError.invalidURLParams
            }
            let pm = try STPPaymentMethod.decodedObject(base64: pmItem)
            return .complete(pm)
        case "logout":
            return .logout
        default:
            throw LinkPopupURLParserError.invalidURLParams
        }
    }

    static func redactedURLForLogging(url: URL?) -> URL? {
        guard let url = url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let originalQueryItems = components.queryItems

        var updatedQueryItems: [URLQueryItem] = []
        originalQueryItems?.forEach { item in
            if item.name == "pm" {
                let updatedItem = URLQueryItem(name: item.name, value: "<redacted>")
                updatedQueryItems.append(updatedItem)
            } else {
                updatedQueryItems.append(item)
            }
        }
        components.queryItems = updatedQueryItems
        return components.url
    }
}

extension STPPaymentMethod {
    static func decodedObject(base64: String) throws -> STPPaymentMethod {
        guard let data = Data(base64Encoded: base64) else {
            throw LinkPopupURLParserError.invalidBase64
        }
        guard let pmDict = try JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any],
              let pm = self.decodedObject(fromAPIResponse: pmDict ) else {
            throw LinkPopupURLParserError.invalidPMJSON
        }
        return pm
    }
}

enum LinkPopupURLParserError: Error {
    case invalidURLParams
    case invalidBase64
    case invalidPMJSON
}
