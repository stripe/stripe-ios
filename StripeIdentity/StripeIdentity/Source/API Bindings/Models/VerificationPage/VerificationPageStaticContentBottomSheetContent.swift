//
//  VerificationPageStaticContentBottomSheetContent.swift
//  StripeIdentity
//
//  Created by Chen Cen on 9/14/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {

    struct VerificationPageStaticContentBottomSheetContent: Decodable, Equatable {
        let bottomsheetId: String
        let title: String?
        let lines: [VerificationPageStaticContentBottomSheetLineContent]
    }

}
