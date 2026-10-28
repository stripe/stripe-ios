//
//  VerificationPageStaticContentBottomSheetLineContent.swift
//  StripeIdentity
//
//  Created by Chen Cen on 9/14/23.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

extension StripeAPI {

    struct VerificationPageStaticContentBottomSheetLineContent: Decodable, Equatable {
        let icon: VerificationPageIconType?
        let title: String
        let content: String
    }

}
