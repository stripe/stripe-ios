//
//  AdditionalKYCRequirementError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/20/26.
//

import Foundation

/// An error from a previous attempt to fulfill an additional KYC requirement.
struct AdditionalKYCRequirementError: Codable, Equatable {

    /// A machine-readable value identifying the error.
    let code: String

    /// A localized explanation of the error.
    /// - TODO: Confirm the API field is named `message` rather than `description`.
    let message: String
}
