//
//  VerificationPageStaticContentIndividualWelcomePage.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/14/23.
//

import Foundation

@_spi(STP) import StripeCore

extension StripeAPI {

    struct VerificationPageStaticContentIndividualWelcomePage: Decodable, Equatable {
        let getStartedButtonText: String
        let privacyPolicy: String
        let title: String
        let lines: [VerificationPageStaticConsentLineContent]
    }

}
