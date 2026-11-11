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

    /// The policy PaymentSheet confirms with: the server's spec if it sent one, otherwise the native table.
    /// The server wins cleanly: a server spec replaces the whole native policy, so a type never runs half server
    /// rules and half native rules. Fields the contract doesn't have take the contract's defaults, not the native ones.
    static func resolved(for type: NativeType, serverSpec: ServerDrivenConfirmSpec?, paymentMethodDataType: String? = nil) -> ConfirmationMetadata? {
        if let serverSpec {
            return ConfirmationMetadata(serverSpec: serverSpec, paymentMethodDataType: paymentMethodDataType ?? type.identifier)
        }
        return native(for: type)
    }
}

extension ConfirmationMetadata.NextAction {
    /// v1's `redirect_to_url`, which a server spec's `next_actions` lists.
    static let redirectToURL = ConfirmationMetadata.NextAction(
        presenter: .redirect(browser: .fromNextAction),
        urlPath: "url",
        fallbackURLPath: nil,
        returnURL: .nextAction,
        appToApp: .universalLinksOnly,
        whileRequiresAction: nil
    )
}

// MARK: - Server spec

extension ConfirmationMetadata {
    /// The whole policy for a server-driven payment method. Every field comes from the spec or, where the contract has
    /// no field, from the contract's documented default. Nothing comes from the native table.
    init(serverSpec spec: ServerDrivenConfirmSpec, paymentMethodDataType: String) {
        let processing: Outcome
        switch spec.processing {
        case .succeed: processing = .succeed
        case .fail: processing = .fail
        case .poll: processing = .poll(seconds: spec.pollSeconds, onTimeout: .fail)
        }
        let requiresAction: Outcome
        switch spec.requiresAction {
        case .cancel: requiresAction = .cancel
        case .poll: requiresAction = .poll(seconds: spec.pollSeconds, onTimeout: .cancel)
        case .succeed: requiresAction = .succeed
        }
        var nextActions: [String: NextAction] = [:]
        for nextAction in spec.nextActions {
            switch nextAction {
            case .redirectToURL:
                nextActions["redirect_to_url"] = .redirectToURL
            }
        }
        self.init(
            params: Params(
                paymentMethodDataType: paymentMethodDataType,
                returnURL: .sentIfSet,
                // `ServerDrivenPaymentMethod` drops a PM whose spec asks for mandate_data or setup_future_usage.
                mandateData: .none,
                setupFutureUsage: .unsupported,
                paymentMethodOptions: []
            ),
            nextActions: nextActions,
            paymentIntent: IntentRules(
                afterConfirm: StatusRules(processing: processing, requiresAction: .performNextAction),
                afterNextAction: StatusRules(processing: processing, requiresAction: requiresAction),
                afterWebViewDismissed: nil
            ),
            setupIntent: nil,
            retrieval: spec.retrieval == .refresh ? .refresh : .retrieve,
            onCancel: .none
        )
    }
}
