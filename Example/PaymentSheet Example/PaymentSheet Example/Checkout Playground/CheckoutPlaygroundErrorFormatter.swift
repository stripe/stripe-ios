//
//  CheckoutPlaygroundErrorFormatter.swift
//  PaymentSheet Example
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

extension CheckoutPlayground {
    /// The message a merchant would show the customer, followed by details for debugging.
    static func errorDisplayText(_ error: Error) -> String {
        "\(error.localizedDescription)\n\n\(errorDebugDetails(error))"
    }

    /// A readable summary of `error` in place of the `String(reflecting:)` dump.
    static func errorDebugDetails(_ error: Error) -> String {
        var lines = [errorName(error)]
        // `CheckoutError` is internal to the SDK, so find the API error it wraps by reflection.
        if let apiError = firstStripeAPIError(in: error) {
            lines += [
                ("type", apiError.type.rawValue),
                ("code", apiError.code),
                ("param", apiError.param),
                ("status", apiError.httpStatusCode.map(String.init)),
                ("request", apiError.requestID),
                ("docs", apiError.docUrl?.absoluteString),
            ].compactMap { label, value in value.map { "\(label): \($0)" } }
        } else if let nsError = firstStripeNSError(in: error) {
            lines += [
                ("type", nsError.userInfo[STPError.stripeErrorTypeKey] as? String),
                ("code", nsError.userInfo[STPError.stripeErrorCodeKey] as? String),
                ("decline code", nsError.userInfo[STPError.stripeDeclineCodeKey] as? String),
                ("message", nsError.userInfo[STPError.errorMessageKey] as? String),
                ("request", nsError.userInfo[STPError.stripeRequestIDKey] as? String),
            ].compactMap { label, value in value?.nonEmpty.map { "\(label): \($0)" } }
        } else if type(of: error) != NSError.self, let debugError = error as? CustomDebugStringConvertible {
            // e.g. `PaymentSheetError`, whose `debugDescription` explains integration errors.
            lines.append(debugError.debugDescription)
        }
        return lines.joined(separator: "\n")
    }

    /// e.g. `CheckoutError.apiError`, or `STPPaymentHandlerErrorDomain 2` for an `NSError`.
    private static func errorName(_ error: Error) -> String {
        if type(of: error) == NSError.self {
            let nsError = error as NSError
            return "\(nsError.domain) \(nsError.code)"
        }
        let caseName = Mirror(reflecting: error).children.first?.label ?? String(describing: error)
        return "\(type(of: error)).\(caseName)"
    }

    private static func firstStripeAPIError(in value: Any, depth: Int = 0) -> StripeAPIError? {
        if let apiError = value as? StripeAPIError {
            return apiError
        }
        guard depth < 6 else { return nil }
        return Mirror(reflecting: value).children.lazy
            .compactMap { firstStripeAPIError(in: $0.value, depth: depth + 1) }
            .first
    }

    /// Follows `NSUnderlyingErrorKey` to the first error carrying Stripe API fields.
    private static func firstStripeNSError(in error: Error) -> NSError? {
        guard type(of: error) == NSError.self else { return nil }
        var current: NSError? = error as NSError
        while let nsError = current {
            if nsError.userInfo[STPError.stripeErrorTypeKey] != nil {
                return nsError
            }
            current = nsError.userInfo[NSUnderlyingErrorKey] as? NSError
        }
        return nil
    }
}
