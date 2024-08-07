//
//  CardElementConfigService.swift
//  StripePaymentsUI
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

private let CardElementConfigEndpoint = URL(string: "https://merchant-ui-api.stripe.com/elements/mobile-card-element-config")!

class CardElementConfigService {
    // The card element does not currently support non-singleton API clients, use the shared one for now.
    var apiClient = STPAPIClient.shared

    static let shared = CardElementConfigService()

    struct CardElementConfig: Decodable {
        struct CardBrandChoice: Decodable {
            let eligible: Bool
        }
        let cardBrandChoice: CardBrandChoice
    }

    enum CardElementConfigFetchState {
        case fetching
        case failed
        case cached(CardElementConfig)
    }

    // We only want to query once per process per PK, as the result should not
    // change for an individual PK over the lifetime of a process.
    private var _configsForPK: [String: CardElementConfigFetchState] = [:]

    func isCBCEligible(onBehalfOf: String? = nil) -> Bool {
        guard let publishableKey = apiClient.publishableKey else {
            // User has not yet initialized a PK, bail
            return false
        }

        let cacheKey = publishableKey + (onBehalfOf ?? "")

        if let fetchState = _configsForPK[cacheKey] {
            switch fetchState {
            case .fetching:
                // Still waiting for a config, so we don't yet know if the user is CBC-eligible.
                return false
            case .failed:
                // If something went wrong, don't fetch again for the life of the process.
                return false
            case .cached(let cardElementConfig):
                return cardElementConfig.cardBrandChoice.eligible
            }
        }

        // Kick off a fetch request
        _configsForPK[cacheKey] = .fetching

        let resultHandler: (Result<CardElementConfig, Error>) -> Void = { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cardElementConfig):
                    // Cache the result for the next time the card element is presented
                    self._configsForPK[cacheKey] = .cached(cardElementConfig)
                case .failure:
                    // Ignore failures, but send an analytic to the server
                    self._configsForPK[cacheKey] = .failed
                    STPAnalyticsClient.sharedClient.logCardElementConfigLoadFailed()
                }
            }
        }

        var parameters: [String: Any] = [:]
        if let onBehalfOf {
            parameters["on_behalf_of"] = onBehalfOf
        }

        apiClient.get(url: CardElementConfigEndpoint, parameters: parameters, ephemeralKeySecret: nil, completion: resultHandler)

        // No answer yet, so we don't know if the user is CBC-eligible
        return false
    }
}
