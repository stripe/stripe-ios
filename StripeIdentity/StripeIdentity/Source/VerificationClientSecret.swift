//
//  VerificationClientSecret.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

struct VerificationClientSecret {

    let verificationSessionId: String
    let urlToken: String
}

extension VerificationClientSecret {
    private static let expectedComponentsCount = 4

    /**
     Initialize from string.
     - returns: nil if the client secret is invalid
     */
    init?(string: String) {
        let components = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "_",
                   maxSplits: VerificationClientSecret.expectedComponentsCount - 1,
                   omittingEmptySubsequences: false)

        // Matching regex /^((vi|vs)_[0-9a-zA-Z]+)_secret_(.+)$/
        guard components.count >= VerificationClientSecret.expectedComponentsCount &&
                (components[0] == "vi" || components[0] == "vs") &&
                !components[1].isEmpty &&
                (components[1].rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil) &&
                components[2] == "secret" &&
                !components[3].isEmpty
        else {
            return nil
        }

        verificationSessionId = "\(components[0])_\(components[1])"
        urlToken = String(components[3])
    }
}
