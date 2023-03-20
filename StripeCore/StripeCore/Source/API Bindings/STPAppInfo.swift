//
//  STPAppInfo.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/20/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Libraries wrapping the Stripe SDK should use this object to provide information about the library, and set it
/// in on `STPAPIClient`.  This information is passed to Stripe so that we can contact you about future issues or critical updates.
/// - seealso: https://stripe.com/docs/building-plugins#setappinfo
public class STPAppInfo {
    /// Initializes an instance of `STPAppInfo`.
    /// - Parameters:
    ///   - name:        The name of your library (e.g. "MyAwesomeLibrary").
    ///   - partnerId:   Your Stripe Partner ID (e.g. "pp_partner_1234"). Required for Stripe Verified Partners, optional otherwise.
    ///   - version:     The version of your library (e.g. "1.2.34"). Optional.
    ///   - url:         The website for your library (e.g. "https://myawesomelibrary.info"). Optional.
    public init(
        name: String,
        partnerId: String?,
        version: String?,
        url: String?
    ) {
        self.name = name
        self.partnerId = partnerId
        self.version = version
        self.url = url
    }

    /// The name of your library (e.g. "MyAwesomeLibrary").
    public private(set) var name: String
    /// Your Stripe Partner ID (e.g. "pp_partner_1234").
    public private(set) var partnerId: String?
    /// The version of your library (e.g. "1.2.34").
    public private(set) var version: String?
    /// The website for your library (e.g. "https://myawesomelibrary.info").
    public private(set) var url: String?
}
