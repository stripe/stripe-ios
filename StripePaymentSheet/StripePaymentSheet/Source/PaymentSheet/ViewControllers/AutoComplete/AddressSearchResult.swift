//
//  AddressSearchResult.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import MapKit

/// Makes testing a `MKLocalSearchCompletion` easier as `MKLocalSearchCompletion` cannot be initialized directly
protocol AddressSearchResult {
    var title: String { get }

    var titleHighlightRanges: [NSValue] { get } // NSValue-wrapped NSRanges

    var subtitle: String { get }

    var subtitleHighlightRanges: [NSValue] { get } // NSValue-wrapped NSRanges

    /// Converts this search result to a `PaymentSheet.Address?`
    /// - Parameter completion: Invoked with a `PaymentSheet.Address?` representation of this address search result
    func asAddress(completion: @escaping (PaymentSheet.Address?) -> Void)
}

extension MKLocalSearchCompletion: AddressSearchResult {
    func asAddress(completion: @escaping (PaymentSheet.Address?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: self)
        let search = MKLocalSearch(request: searchRequest)

        search.start { (response, _) in
            let placemark = response?.mapItems.first?.placemark
            completion(placemark?.asAddress)
        }
    }
}

extension MKPlacemark {
    /// Converts this placemark into an address that can be interpreted by PaymentSheet
    var asAddress: PaymentSheet.Address {
        return PaymentSheet.Address(city: locality,
                                    country: isoCountryCode,
                                    line1: name,
                                    line2: nil, // Can't get line 2 from auto complete
                                    postalCode: postalCode,
                                    state: administrativeArea)
    }
}
