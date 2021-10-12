//
//  VerificationSheetController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/7/21.
//

import Foundation
@_spi(STP) import StripeUICore

final class VerificationSheetController {

    let addressSpecProvider = AddressSpecProvider.shared


    // TODO(mludowise|IDPROD-2539): Return the first screen in the IDV flow.
    // Temporarily using completion block with no params until screen routing is implemented.
    func load(completion: @escaping () -> Void) {
        // TODO(mludowise|IDPROD-2540): Post to VerificationPage endpoint and return response in result.
        addressSpecProvider.loadAddressSpecs(completion: completion)
    }
}
