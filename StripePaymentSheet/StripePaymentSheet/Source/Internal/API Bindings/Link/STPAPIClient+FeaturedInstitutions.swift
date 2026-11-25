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
    /// Only the publishable key is required.
    /// - Parameter country: The customer's country. The backend picks which country's institutions to return, so this
    ///   lets IBP support more countries without an SDK update. Defaults to the US, where instant debits launched.
    func featuredInstitutionsForInstantDebits(country: String?, limit: Int) async throws -> FeaturedInstitutionList {
        let parameters: [String: Any] = [
            "product": "instant_debits",
            "country": country ?? "US",
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
