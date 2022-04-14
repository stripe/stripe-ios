//
//  VerificationPageDataUpdate.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

struct VerificationPageDataUpdate: Encodable, Equatable {

    let clearData: VerificationPageClearData?
    let collectedData: VerificationPageCollectedData?
}
