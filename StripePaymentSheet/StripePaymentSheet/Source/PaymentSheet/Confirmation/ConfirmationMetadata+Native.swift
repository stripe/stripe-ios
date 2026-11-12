//
//  ConfirmationMetadata+Native.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/10/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// The default table: one `ConfirmationMetadata` per payment method type PaymentSheet confirms, from the bundled
/// `confirmation_metadata.json` (`ConfirmationMetadata+Wire.swift`). It's a stand-in for the server sending the same
/// entries; `ConfirmationMetadataParityTests` compares it with what STPPaymentHandler actually does.
extension ConfirmationMetadata {
    typealias NativeType = STPPaymentMethodType

    /// Every type PaymentSheet confirms through STPPaymentHandler: `PaymentSheet.supportedPaymentMethods` plus Link.
    static var nativeTypes: [NativeType] {
        return PaymentSheet.supportedPaymentMethods + [.link]
    }

    /// Loaded once. A bundled file with problems is an SDK bug; the affected types keep confirming with STPPaymentHandler.
    static let bundledTable: Table = {
        let table = loadBundledTable()
        if !table.problems.isEmpty {
            stpAssertionFailure("confirmation_metadata.json has problems: \(table.problems)")
        }
        return table
    }()

    /// The native policy for `type`, or nil if PaymentSheet doesn't confirm it.
    static func native(for type: NativeType) -> ConfirmationMetadata? {
        guard nativeTypes.contains(type) else {
            return nil
        }
        return bundledTable.entries[type.identifier]
    }
}
