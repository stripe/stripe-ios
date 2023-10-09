//
//  VerificationPageStaticConsentLineContent.swift
//  StripeIdentity
//
//  Created by Chen Cen on 9/20/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {

    struct VerificationPageStaticConsentLineContent: Decodable, Equatable {
        let icon: VerificationPageIconType
        let content: String
    }

}
