//
//  FinancialConnectionsPartner.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

struct FinancialConnectionsAuthSession: Decodable {
    enum Flow: String, SafeEnumCodable, Equatable {
        case directWebview = "direct_webview"
        case finicityConnectV2Lite = "finicity_connect_v2_lite"
        case finicityConnectV2Oauth = "finicity_connect_v2_oauth"
        case finicityConnectV2OauthWebview = "finicity_connect_v2_oauth_webview"
        case finicityConnectV2OauthRedirect = "finicity_connect_v2_oauth_redirect"
        case mxConnect = "mx_connect"
        case mxOauth = "mx_oauth"
        case mxOauthWebview = "mx_oauth_webview"
        case mxOauthAppToApp = "mx_oauth_app_to_app"
        case testmode = "testmode"
        case testmodeOauth = "testmode_oauth"
        case testmodeOauthWebview = "testmode_oauth_webview"
        case truelayerEmbedded = "truelayer_embedded"
        case truelayerOauth = "truelayer_oauth"
        case wellsFargo = "wells_fargo"
        case unparsable

        func toPartner() -> FinancialConnectionsPartner? {
            switch self {
            case .finicityConnectV2Oauth:
                fallthrough
            case .finicityConnectV2OauthWebview:
                fallthrough
            case .finicityConnectV2Lite:
                fallthrough
            case .finicityConnectV2OauthRedirect:
                return .finicity
            case .mxConnect:
                fallthrough
            case .mxOauth:
                fallthrough
            case .mxOauthWebview:
                return .mx
            case .mxOauthAppToApp:
                return .mx
            case .truelayerEmbedded:
                fallthrough
            case .truelayerOauth:
                return .trueLayer
            case .wellsFargo:
                return .wellsFargo
            case .directWebview:
                fallthrough
            case .testmode:
                fallthrough
            case .testmodeOauth:
                fallthrough
            case .testmodeOauthWebview:
                fallthrough
            case .unparsable:
                assertionFailure("Expected to never access \(self)")
                return nil
            }
        }
    }

    let id: String
    let flow: Flow?
    let institutionSkipAccountSelection: Bool?
    let nextPane: FinancialConnectionsSessionManifest.NextPane
    let showPartnerDisclosure: Bool?
    let skipAccountSelection: Bool?
    let url: String?
    let isOauth: Bool?
    let display: Display?

    var isOauthNonOptional: Bool {
        return isOauth ?? false
    }

    var requiresNativeRedirect: Bool {
        return url?.hasNativeRedirectPrefix ?? false
    }

    var partner: FinancialConnectionsPartner? {
        return (showPartnerDisclosure ?? false) ? flow?.toPartner() : nil
    }

    struct Display: Decodable {
        let text: Text?

        struct Text: Decodable {
            let oauthPrepane: FinancialConnectionsOAuthPrepane?
        }
    }
}

// this is a client-side enum (doesn't come from server)
enum FinancialConnectionsPartner {
    case finicity
    case mx
    case trueLayer
    case wellsFargo

    var name: String {
        switch self {
        case .finicity:
            return "Finicity"
        case .mx:
            return "MX"
        case .trueLayer:
            return "TrueLayer"
        case .wellsFargo:
            return "Wells Fargo"
        }
    }

    var icon: UIImage? {
        switch self {
        case .finicity:
            return Image.finicity.makeImage()
        case .mx:
            return Image.mx.makeImage()
        case .wellsFargo:
            // we never show icons for direct integrations
            return nil
        case .trueLayer:
            // icon not needed until EU support
            return nil
        }
    }
}
