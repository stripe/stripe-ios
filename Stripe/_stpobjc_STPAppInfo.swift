//
//  _stpobjc_STPAppInfo.swift
//  StripeiOS
//
//  Created by David Estes on 9/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import StripeCore

/// Libraries wrapping the Stripe SDK should use this object to provide information about the library, and set it
/// in on `STPAPIClient`.  This information is passed to Stripe so that we can contact you about future issues or critical updates.
/// - seealso: https://stripe.com/docs/building-plugins#setappinfo
/// :nodoc:
@objc(STPAppInfo)
public class _stpobjc_STPAppInfo: NSObject {
    var _appInfo: STPAppInfo
    
    /// Initializes an instance of `STPAppInfo`.
    /// - Parameters:
    ///   - name:        The name of your library (e.g. "MyAwesomeLibrary").
    ///   - partnerId:   Your Stripe Partner ID (e.g. "pp_partner_1234"). Required for Stripe Verified Partners, optional otherwise.
    ///   - version:     The version of your library (e.g. "1.2.34"). Optional.
    ///   - url:         The website for your library (e.g. "https://myawesomelibrary.info"). Optional.
    @objc public init(
        name: String,
        partnerId: String?,
        version: String?,
        url: String?
    ) {
        _appInfo = STPAppInfo(name: name, partnerId: partnerId, version: version, url: url)
    }
    
    init?(appInfo: STPAppInfo?) {
        if let appInfo = appInfo {
            _appInfo = appInfo
        } else {
            return nil
        }
    }

    /// The name of your library (e.g. "MyAwesomeLibrary").
    @objc public var name: String {
        _appInfo.name
    }
    /// Your Stripe Partner ID (e.g. "pp_partner_1234").
    @objc public var partnerId: String? {
        _appInfo.partnerId
    }
    /// The version of your library (e.g. "1.2.34").
    @objc public var version: String? {
        _appInfo.version
    }
    /// The website for your library (e.g. "https://myawesomelibrary.info").
    @objc public var url: String? {
        _appInfo.url
    }
}
