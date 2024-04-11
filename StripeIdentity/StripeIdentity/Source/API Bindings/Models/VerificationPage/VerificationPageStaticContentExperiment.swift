//
//  VerificationPageStaticContentExperiment.swift
//  StripeIdentity
//
//  Created by Chen Cen on 3/8/24.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {

    struct VerificationPageStaticContentExperiment: Decodable, Equatable {
        let experimentName: String
        let eventName: String
        let eventMetadata: [String: String]
    }

}
