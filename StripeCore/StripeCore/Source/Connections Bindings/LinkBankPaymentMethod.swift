//
//  LinkBankPaymentMethod.swift
//  StripeCore
//
//  Created by Till Hellmund on 10/11/24.
//

import Foundation

/// This struct represents the encoded `PaymentMethod` that we receive during the Instant Debits flow.
/// We don't decode it into a proper struct to prevent said struct (which would live in StripeCore) from getting
/// out-of-sync with `STPPaymentMethod`, which this payment method will eventually be decoded into.
@_spi(STP) public struct LinkBankPaymentMethod: UnknownFieldsDecodable, Equatable {
    public var _allResponseFieldsStorage: NonEncodableParameters?
    public var id: String
}
