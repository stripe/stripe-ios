//
//  LinkBrand.swift
//  StripeCore
//
//  Created by Sophia Horng on 4/24/26.
//

import Foundation

@_spi(STP) @frozen public enum LinkBrand: String, SafeEnumCodable, Equatable {
    case link = "link"
    case onelink = "notlink"
    case unparsable

    /// Brand names are proper nouns, so keep the source-of-truth user-facing value here.
    @_spi(STP) public var displayName: String {
        switch self {
        case .link, .unparsable:
            return "Link"
        case .onelink:
            return "Onelink"
        }
    }

    @_spi(STP) public var websiteURL: URL {
        switch self {
        case .link, .unparsable:
            return URL(string: "https://link.com")!
        case .onelink:
            return URL(string: "https://onelink.com")!
        }
    }

    @_spi(STP) public var termsURL: URL {
        switch self {
        case .link, .unparsable:
            return URL(string: "https://link.co/terms")!
        case .onelink:
            return URL(string: "https://onelink.com/terms")!
        }
    }

    @_spi(STP) public var privacyURL: URL {
        switch self {
        case .link, .unparsable:
            return URL(string: "https://link.co/privacy")!
        case .onelink:
            return URL(string: "https://onelink.com/privacy")!
        }
    }

    @_spi(STP) public var achAuthorizationURL: URL {
        switch self {
        case .link, .unparsable:
            return URL(string: "https://link.com/terms/ach-authorization")!
        case .onelink:
            return URL(string: "https://onelink.com/terms/ach-authorization")!
        }
    }

    @_spi(STP) public var promotionTermsURL: URL {
        switch self {
        case .link, .unparsable:
            return URL(string: "https://link.com/promotion-terms")!
        case .onelink:
            return URL(string: "https://onelink.com/promotion-terms")!
        }
    }

    @_spi(STP) public var supportContactURL: URL {
        switch self {
        case .link, .unparsable:
            return URL(string: "https://support.link.co/contact/email?skipVerification=true")!
        case .onelink:
            return URL(string: "https://support.onelink.com/contact/email?skipVerification=true")!
        }
    }

    @_spi(STP) public func brandAwareLegalSupportURL(for url: URL) -> URL {
        guard self == .onelink, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        let host = components.host?.lowercased()
        switch host {
        case "link.co", "www.link.co":
            switch components.path {
            case "/terms":
                return termsURL
            case "/privacy":
                return privacyURL
            default:
                return url
            }
        case "link.com", "www.link.com":
            switch components.path {
            case "", "/":
                return websiteURL
            case "/terms":
                return URL(string: "https://onelink.com/terms")!
            case "/privacy":
                return privacyURL
            case "/terms/ach-authorization":
                return achAuthorizationURL
            case "/promotion-terms":
                return promotionTermsURL
            default:
                return url
            }
        case "support.link.co", "www.support.link.co":
            components.scheme = "https"
            components.host = "support.onelink.com"
            return components.url ?? url
        default:
            return url
        }
    }
}
