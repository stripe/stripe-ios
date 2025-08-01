//
//  STPAPIClient+CryptoOnramp.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import Foundation
import StripeCore

extension STPAPIClient {

    /// Sets the publishable key to a test merchant configured to work with crypto onramp APIs.
    func setUpPublishableKey() {
        publishableKey = "pk_test_51K9W3OHMaDsveWq0oLP0ZjldetyfHIqyJcz27k2BpMGHxu9v9Cei2tofzoHncPyk3A49jMkFEgTOBQyAMTUffRLa00xzzARtZO"
    }
}
