//
//  FinancialConnectionsPartner.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

struct FinancialConnectionsAuthorizationSession: Decodable {
    enum Flow: String, SafeEnumCodable, Equatable {
        case directWebview = "direct_webview"
        case finicityConnectV2Lite = "finicity_connect_v2_lite"
        case finicityConnectV2Oauth = "finicity_connect_v2_oauth"
        case finicityConnectV2OauthWebview = "finicity_connect_v2_oauth_webview"
        case finicityConnectV2OauthRedirect = "finicity_connect_v2_oauth_redirect"
        case mxConnect = "mx_connect"
        case mxOauth = "mx_oauth"
        case mxOauthWebview = "mx_oauth_webview"
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
        
        func isOAuth() -> Bool {
            switch self {
            case .directWebview:
                fallthrough
            case .finicityConnectV2Oauth:
                fallthrough
            case .finicityConnectV2OauthWebview:
                fallthrough
            case .finicityConnectV2OauthRedirect:
                fallthrough
            case .mxOauth:
                fallthrough
            case .mxOauthWebview:
                fallthrough
            case .testmodeOauth:
                fallthrough
            case .testmodeOauthWebview:
                fallthrough
            case .truelayerEmbedded:
                fallthrough
            case .truelayerOauth:
                fallthrough
            case .wellsFargo:
                return true
                
            case .finicityConnectV2Lite:
                fallthrough
            case .mxConnect:
                fallthrough
            case .testmode:
                fallthrough
            case .unparsable:
                return false
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
    
    var shouldShowPrepane: Bool {
        return flow?.isOAuth() ?? false
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
            return nil // TODO(kgaidis): do we need a wells fargo icon?
        case .trueLayer:
            return nil // TODO(kgaidis): do we need a true layer icon?
        }
    }
}
