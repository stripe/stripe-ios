//
//  AdditionalKYCRequirementError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// An error from a previous attempt to fulfill an additional KYC requirement.
struct AdditionalKYCRequirementError: Decodable, Equatable {

    /// A machine-readable value identifying the error.
    let code: String

    /// A localized explanation of the error.
    let message: String
}
