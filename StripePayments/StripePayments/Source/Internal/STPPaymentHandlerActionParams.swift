//
//  STPPaymentHandlerActionParams.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 6/28/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import AuthenticationServices
import Foundation
@_spi(InternalOnlyAPI) import StripeCore
import UIKit

#if canImport(Stripe3DS2)
    import Stripe3DS2
#endif

/// The states relevant while polling an Intent for an out-of-band action.
@_spi(InternalOnlyAPI) @frozen public enum STPPaymentHandlerPollingStatus: Equatable {
    case pending
    case processing
    case succeeded
    case failed
}

/// A retrieved polling status and the mutation that accepts its Intent as the action's latest value.
@_spi(InternalOnlyAPI) public struct STPPaymentHandlerPollingResult {
    @_spi(InternalOnlyAPI) public let status: STPPaymentHandlerPollingStatus
    private let updateActionIntentBlock: () -> Void

    init(status: STPPaymentHandlerPollingStatus, updateActionIntent: @escaping () -> Void) {
        self.status = status
        self.updateActionIntentBlock = updateActionIntent
    }

    @_spi(InternalOnlyAPI) public func updateActionIntent() {
        updateActionIntentBlock()
    }
}

@_spi(InternalOnlyAPI) public protocol STPPaymentHandlerActionParams: NSObject, ASWebAuthenticationPresentationContextProviding {
    var threeDS2Service: STDSThreeDS2Service? { get }
    var threeDS2Transaction: STDSTransaction? { get set }
    var authenticationContext: STPAuthenticationContext { get }
    var apiClient: STPAPIClient { get }
    var threeDSCustomizationSettings: STPThreeDSCustomizationSettings { get }
    var returnURLString: String? { get }
    var intentStripeID: String { get }
    /// The current intent status interpreted for its selected polling payment method.
    var pollingStatus: STPPaymentHandlerPollingStatus { get }
    /// Returns the payment or setup intent's next action
    func nextAction() -> STPIntentAction?
    /// Retrieves the latest Intent and its polling status without mutating the action.
    func retrievePollingResult(completion: @escaping (STPPaymentHandlerPollingResult?) -> Void)
    /// Completes the action at most once. Must be called on the main thread.
    func complete(with status: STPPaymentHandlerActionStatus, error: NSError?)
}

@_spi(InternalOnlyAPI) public extension STPPaymentHandlerActionParams {
    /// Bounds a final status check so canceling does not wait for the network request timeout.
    /// A response arriving after the deadline is ignored.
    func retrievePollingResult(timeout: TimeInterval, completion: @escaping (STPPaymentHandlerPollingResult?) -> Void) {
        dispatchPrecondition(condition: .onQueue(.main))
        var didComplete = false
        let finish: (STPPaymentHandlerPollingResult?) -> Void = { result in
            guard !didComplete else { return }
            didComplete = true
            completion(result)
        }
        let timeoutWorkItem = DispatchWorkItem { finish(nil) }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)
        retrievePollingResult { result in
            timeoutWorkItem.cancel()
            finish(result)
        }
    }
}

private func pollingRetrievalFailure(_ error: Error?, isPayto: Bool) -> STPPaymentHandlerPollingResult? {
    // Preserve the existing retry behavior for other polling payment methods.
    guard isPayto, let error = error as NSError? else { return nil }
    if error.domain == NSURLErrorDomain {
        return nil
    }
    if error.domain == STPError.stripeDomain {
        let code = error.userInfo[STPError.stripeErrorCodeKey] as? String
        let type = error.userInfo[STPError.stripeErrorTypeKey] as? String
        if error.code == STPErrorCode.connectionError.rawValue
            || code == "lock_timeout" || code == "rate_limit"
            || type == "rate_limit_error" || error.userInfo[STPError.httpStatusCodeKey] as? Int == 429 {
            return nil
        }
    }
    return STPPaymentHandlerPollingResult(status: .failed, updateActionIntent: {})
}

@_spi(InternalOnlyAPI)
public class STPPaymentHandlerPaymentIntentActionParams: NSObject, STPPaymentHandlerActionParams {
    private var serviceInitialized = false
    // Keep the selected flow when later responses omit next_action and the expanded payment method.
    private let usesPaytoPolling: Bool

    @_spi(InternalOnlyAPI) public let authenticationContext: STPAuthenticationContext
    @_spi(InternalOnlyAPI) public let apiClient: STPAPIClient
    @_spi(InternalOnlyAPI) public let threeDSCustomizationSettings: STPThreeDSCustomizationSettings
    private var paymentIntentCompletion: STPPaymentHandlerActionPaymentIntentCompletionBlock?
    @_spi(InternalOnlyAPI) public let returnURLString: String?
    @_spi(InternalOnlyAPI) public var paymentIntent: STPPaymentIntent
    @_spi(InternalOnlyAPI) public var threeDS2Transaction: STDSTransaction?

    @_spi(InternalOnlyAPI) public var intentStripeID: String {
        return paymentIntent.stripeId
    }

    private var _threeDS2Service: STDSThreeDS2Service?

    @_spi(InternalOnlyAPI) public var threeDS2Service: STDSThreeDS2Service? {
        if !serviceInitialized {
            serviceInitialized = true
            _threeDS2Service = STDSThreeDS2Service()

            STDSSwiftTryCatch.try(
                {
                    let configParams = STDSConfigParameters()
                    if !self.paymentIntent.livemode {
                        configParams.addParameterNamed(
                            "kInternalStripeTestingConfigParam",
                            withValue: "Y"
                        )
                    }
                    self._threeDS2Service?.initialize(
                        withConfig: configParams,
                        locale: Locale.autoupdatingCurrent,
                        uiSettings: self.threeDSCustomizationSettings.uiCustomization
                            .uiCustomization
                    )
                },
                catch: { _ in
                    self._threeDS2Service = nil
                },
                finallyBlock: {
                }
            )
        }

        return _threeDS2Service
    }

    init(
        apiClient: STPAPIClient,
        authenticationContext: STPAuthenticationContext,
        threeDSCustomizationSettings: STPThreeDSCustomizationSettings,
        paymentIntent: STPPaymentIntent,
        returnURL returnURLString: String?,
        completion: @escaping STPPaymentHandlerActionPaymentIntentCompletionBlock
    ) {
        self.apiClient = apiClient
        self.authenticationContext = authenticationContext
        self.threeDSCustomizationSettings = threeDSCustomizationSettings
        self.returnURLString = returnURLString
        self.paymentIntent = paymentIntent
        self.usesPaytoPolling = paymentIntent.nextAction?.type == .paytoAwaitAuthorization || paymentIntent.paymentMethod?.type == .payto || paymentIntent.paymentMethodTypes == [.payto]
        self.paymentIntentCompletion = completion
        super.init()
    }

    @_spi(InternalOnlyAPI) public var pollingStatus: STPPaymentHandlerPollingStatus {
        paymentIntent.status.paymentHandlerPollingStatus(isPayto: usesPaytoPolling)
    }

    @_spi(InternalOnlyAPI) public func nextAction() -> STPIntentAction? {
        return paymentIntent.nextAction
    }

    @_spi(InternalOnlyAPI) public func retrievePollingResult(completion: @escaping (STPPaymentHandlerPollingResult?) -> Void) {
        apiClient.retrievePaymentIntent(withClientSecret: paymentIntent.clientSecret) { [weak self] paymentIntent, error in
            guard let self else {
                completion(nil)
                return
            }
            guard let paymentIntent else {
                completion(pollingRetrievalFailure(error, isPayto: self.usesPaytoPolling))
                return
            }
            completion(STPPaymentHandlerPollingResult(status: paymentIntent.status.paymentHandlerPollingStatus(isPayto: self.usesPaytoPolling), updateActionIntent: { [weak self] in
                self?.paymentIntent = paymentIntent
            }))
        }
    }

    @_spi(InternalOnlyAPI) public func complete(with status: STPPaymentHandlerActionStatus, error: NSError?) {
        // Redirect callbacks can race. Consume the completion before invoking it to also allow reentrancy.
        let completion = paymentIntentCompletion
        paymentIntentCompletion = nil
        completion?(status, paymentIntent, error)
    }

    // Translate the STPAuthenticationContext to an ASPresentationAnchor if possible
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return authenticationContext.authenticationPresentingViewController().view.window ?? stp_makeFallbackPresentationAnchor()
    }
}

internal class STPPaymentHandlerSetupIntentActionParams: NSObject, STPPaymentHandlerActionParams {
    private var serviceInitialized = false
    // Keep the selected flow when later responses omit next_action and the expanded payment method.
    private let usesPaytoPolling: Bool

    let authenticationContext: STPAuthenticationContext
    let apiClient: STPAPIClient
    let threeDSCustomizationSettings: STPThreeDSCustomizationSettings
    private var setupIntentCompletion: STPPaymentHandlerActionSetupIntentCompletionBlock?
    let returnURLString: String?
    var setupIntent: STPSetupIntent
    var threeDS2Transaction: STDSTransaction?

    var intentStripeID: String {
        return setupIntent.stripeID
    }

    private var _threeDS2Service: STDSThreeDS2Service?

    var threeDS2Service: STDSThreeDS2Service? {
        if !serviceInitialized {
            serviceInitialized = true
            _threeDS2Service = STDSThreeDS2Service()

            STDSSwiftTryCatch.try(
                {
                    let configParams = STDSConfigParameters()
                    if !self.setupIntent.livemode {
                        configParams.addParameterNamed(
                            "kInternalStripeTestingConfigParam",
                            withValue: "Y"
                        )
                    }
                    self._threeDS2Service?.initialize(
                        withConfig: configParams,
                        locale: Locale.autoupdatingCurrent,
                        uiSettings: self.threeDSCustomizationSettings.uiCustomization
                            .uiCustomization
                    )
                },
                catch: { _ in
                    self._threeDS2Service = nil
                },
                finallyBlock: {
                }
            )
        }

        return _threeDS2Service
    }

    init(
        apiClient: STPAPIClient,
        authenticationContext: STPAuthenticationContext,
        threeDSCustomizationSettings: STPThreeDSCustomizationSettings,
        setupIntent: STPSetupIntent,
        returnURL returnURLString: String?,
        completion: @escaping STPPaymentHandlerActionSetupIntentCompletionBlock
    ) {
        self.apiClient = apiClient
        self.authenticationContext = authenticationContext
        self.threeDSCustomizationSettings = threeDSCustomizationSettings
        self.returnURLString = returnURLString
        self.setupIntent = setupIntent
        self.usesPaytoPolling = setupIntent.nextAction?.type == .paytoAwaitAuthorization || setupIntent.paymentMethod?.type == .payto || setupIntent.paymentMethodTypes == [.payto]
        self.setupIntentCompletion = completion
        super.init()
    }

    var pollingStatus: STPPaymentHandlerPollingStatus {
        setupIntent.status.paymentHandlerPollingStatus(isPayto: usesPaytoPolling)
    }

    func nextAction() -> STPIntentAction? {
        return setupIntent.nextAction
    }

    func retrievePollingResult(completion: @escaping (STPPaymentHandlerPollingResult?) -> Void) {
        apiClient.retrieveSetupIntent(withClientSecret: setupIntent.clientSecret) { [weak self] setupIntent, error in
            guard let self else {
                completion(nil)
                return
            }
            guard let setupIntent else {
                completion(pollingRetrievalFailure(error, isPayto: self.usesPaytoPolling))
                return
            }
            completion(STPPaymentHandlerPollingResult(status: setupIntent.status.paymentHandlerPollingStatus(isPayto: self.usesPaytoPolling), updateActionIntent: { [weak self] in
                self?.setupIntent = setupIntent
            }))
        }
    }

    func complete(with status: STPPaymentHandlerActionStatus, error: NSError?) {
        // Redirect callbacks can race. Consume the completion before invoking it to also allow reentrancy.
        let completion = setupIntentCompletion
        setupIntentCompletion = nil
        completion?(status, setupIntent, error)
    }

    // Translate the STPAuthenticationContext to an ASPresentationAnchor if possible
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return authenticationContext.authenticationPresentingViewController().view.window ?? stp_makeFallbackPresentationAnchor()
    }
}

private extension STPPaymentIntentStatus {
    func paymentHandlerPollingStatus(isPayto: Bool) -> STPPaymentHandlerPollingStatus {
        switch self {
        case .requiresAction:
            return .pending
        case .processing where isPayto:
            return .processing
        case .succeeded:
            return .succeeded
        case .requiresCapture where isPayto:
            return .succeeded
        case .unknown, .requiresPaymentMethod, .requiresConfirmation, .processing, .requiresCapture, .canceled:
            return .failed
        @unknown default:
            return .failed
        }
    }
}

private extension STPSetupIntentStatus {
    func paymentHandlerPollingStatus(isPayto: Bool) -> STPPaymentHandlerPollingStatus {
        switch self {
        case .requiresAction:
            return .pending
        case .processing where isPayto:
            return .processing
        case .succeeded:
            return .succeeded
        case .unknown, .requiresPaymentMethod, .requiresConfirmation, .processing, .canceled:
            return .failed
        @unknown default:
            return .failed
        }
    }
}

/// Creates a fallback ASPresentationAnchor when no window is available.
/// On visionOS, UIWindow() without a scene is deprecated, so we find a scene first.
private func stp_makeFallbackPresentationAnchor() -> ASPresentationAnchor {
    #if !os(visionOS)
    return ASPresentationAnchor()
    #else
    if let windowScene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first {
        return UIWindow(windowScene: windowScene)
    }
    // No windowScene was available on visionOS, so we need to bail.
    fatalError()
    #endif
}
