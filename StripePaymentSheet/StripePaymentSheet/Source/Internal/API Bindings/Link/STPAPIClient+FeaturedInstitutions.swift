//
//  STPAPIClient+FeaturedInstitutions.swift
//  StripePaymentSheet
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// A bank institution featured by Financial Connections, e.g. Chase or Bank of America.
struct FeaturedInstitution: Decodable, Equatable {
    struct Icon: Decodable, Equatable {
        let `default`: String?
    }

    let id: String
    let name: String
    let icon: Icon?

    /// The URL of the institution's icon, if it has a real (non-placeholder) one.
    var iconURL: URL? {
        guard let urlString = icon?.default, !urlString.isEmpty else {
            return nil
        }
        return URL(string: urlString)
    }
}

struct FeaturedInstitutionList: Decodable, Equatable {
    let data: [FeaturedInstitution]
}

extension STPAPIClient {
    /// Fetches the featured institutions shown on the instant debits "Bank" row.
    /// Mirrors the Stripe.js request: only the publishable key is required, and instant debits is US-only.
    func featuredInstitutionsForInstantDebits(limit: Int) async throws -> FeaturedInstitutionList {
        let parameters: [String: Any] = [
            "product": "instant_debits",
            "country": "US",
            "limit": limit,
        ]
        return try await withCheckedThrowingContinuation { continuation in
            get(
                resource: "connections/featured_institutions",
                parameters: parameters
            ) { (result: Result<FeaturedInstitutionList, Error>) in
                continuation.resume(with: result)
            }
        }
    }
}
