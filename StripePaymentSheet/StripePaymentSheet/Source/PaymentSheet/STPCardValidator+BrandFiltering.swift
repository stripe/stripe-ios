//
//  STPCardValidator+BrandFiltering.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/11/24.
//

import Foundation

extension STPCardValidator {
    class func possibleBrands(forNumber cardNumber: String,
                              with cardBrandFilter: CardBrandFilter,
                              completion: @escaping (Result<Set<STPCardBrand>, Error>) -> Void) {
        possibleBrands(forNumber: cardNumber) { result in
            completion(result.map { brands in
                brands.filter { cardBrandFilter.isAccepted(cardBrand: $0) }
            })
        }
    }
}
