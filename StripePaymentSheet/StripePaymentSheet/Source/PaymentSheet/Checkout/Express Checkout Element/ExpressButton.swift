//
//  ExpressButton.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/21/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Represents the display state of the Link wallet button.
enum LinkButtonState: Equatable {
    /// No Link account — show signed-out state.
    case signedOut
    /// Signed in with an email address but no default payment method.
    case signedIn(email: String)
    /// Signed in with a saved payment method.
    case withPaymentMethod(last4: String)

    static func from(_ account: PaymentSheetLinkAccount?) -> LinkButtonState {
        guard let account, account.isRegistered else { return .signedOut }
        if let last4 = account.displayablePaymentDetails?.last4 {
            return .withPaymentMethod(last4: last4)
        }
        return .signedIn(email: account.email)
    }
}

/// The available express button types for a checkout session.
/// Analogous to Android's `ExpressButtonType`.
@_spi(STP)
public enum ExpressButtonType: Equatable {
    case applePay
    case link
}

/// Internal representation of a wallet button rendered by ``Checkout/ExpressCheckoutElementUIView``.
enum ExpressButton {
    case applePay
    case link(brand: LinkBrand, state: LinkButtonState)
}

extension ExpressButtonType {
    static func available(
        in elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration,
        hasApplePayConfiguration: Bool
    ) -> [ExpressButtonType] {
        var types: [ExpressButtonType] = []

        for type in elementsSession.orderedPaymentMethodTypesAndWallets {
            switch type {
            case "apple_pay":
                if isApplePayAvailable(in: elementsSession, configuration: configuration, hasApplePayConfiguration: hasApplePayConfiguration) {
                    types.append(.applePay)
                }
            case "link":
                if isLinkAvailable(in: elementsSession, configuration: configuration) {
                    types.append(.link)
                }
            default:
                break
            }
        }

        // Link in passthrough mode may not appear in orderedPaymentMethodTypesAndWallets.
        if !types.contains(.link),
           elementsSession.linkPassthroughModeEnabled,
           isLinkAvailable(in: elementsSession, configuration: configuration) {
            types.append(.link)
        }

        return types
    }

    private static func isApplePayAvailable(
        in elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration,
        hasApplePayConfiguration: Bool
    ) -> Bool {
        return configuration.applePayVisibility != .never
            && hasApplePayConfiguration
            && StripeAPI.deviceSupportsApplePay()
            && elementsSession.isApplePayEnabled
    }

    private static func isLinkAvailable(
        in elementsSession: STPElementsSession,
        configuration: ExpressCheckoutElement.Configuration
    ) -> Bool {
        let isInHoldback: Bool = {
            guard let assignments = elementsSession.experimentsData?.experimentAssignments else { return false }
            return assignments[LinkGlobalHoldback.experimentName] == .holdback
                || assignments[LinkABTest.experimentName] == .holdback
        }()
        return configuration.linkVisibility != .never
            && elementsSession.supportsLink
            && !isInHoldback
    }
}

extension ExpressButton {
    static func from(
        _ types: [ExpressButtonType],
        elementsSession: STPElementsSession,
        linkButtonState: LinkButtonState
    ) -> [ExpressButton] {
        let linkBrand = elementsSession.linkBrand ?? .link
        return types.map { type in
            switch type {
            case .applePay:
                return .applePay
            case .link:
                return .link(brand: linkBrand, state: linkButtonState)
            }
        }
    }
}
