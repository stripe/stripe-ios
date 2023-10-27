//
//  LinkPopupURLParser.swift
//  StripePaymentSheet
//

import Foundation
import StripePayments

struct LinkResult {
    enum LinkStatus: String {
        case complete
        case logout
    }
    let link_status: LinkStatus
    let pm: STPPaymentMethod
}

class LinkPopupURLParser {
    static func result(with resultURL: URL) throws -> LinkResult {
        let components = URLComponents(url: resultURL, resolvingAgainstBaseURL: false)
        guard let statusItem = components?.queryItems?.first(where: { $0.name == "link_status" })?.value,
              let status = LinkResult.LinkStatus(rawValue: statusItem),
              let pmItem = components?.queryItems?.first(where: { $0.name == "pm" })?.value else {
            throw LinkPopupURLParserError.invalidURLParams
        }
        let pm = try STPPaymentMethod.decodedObject(base64: pmItem)
        return LinkResult(link_status: status, pm: pm)
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
