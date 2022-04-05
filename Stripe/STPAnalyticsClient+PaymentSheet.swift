//
//  STPAnalyticsClient+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeApplePay

extension STPAnalyticsClient {
    // MARK: - Log events
    func logPaymentSheetInitialized(
        isCustom: Bool = false, configuration: PaymentSheet.Configuration
    ) {
        logPaymentSheetEvent(event: paymentSheetInitEventValue(
                                isCustom: isCustom,
                                configuration: configuration))
    }

    func logPaymentSheetPayment(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        result: PaymentSheetResult,
        linkEnabled: Bool,
        activeLinkSession: Bool
    ) {
        var success = false
        switch result {
        case .canceled:
            // We don't report these to analytics, bail out.
            return
        case .failed(error: _):
            success = false
        case .completed:
            success = true
        }

        logPaymentSheetEvent(
            event: paymentSheetPaymentEventValue(
                isCustom: isCustom,
                paymentMethod: paymentMethod,
                success: success
            ),
            duration: AnalyticsHelper.shared.getDuration(for: .checkout),
            linkEnabled: linkEnabled,
            activeLinkSession: activeLinkSession
        )
    }

    func logPaymentSheetShow(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        linkEnabled: Bool,
        activeLinkSession: Bool
    ) {
        AnalyticsHelper.shared.startTimeMeasurement(.checkout)
        logPaymentSheetEvent(
            event: paymentSheetShowEventValue(isCustom: isCustom, paymentMethod: paymentMethod),
            linkEnabled: linkEnabled,
            activeLinkSession: activeLinkSession
        )
    }
    
    func logPaymentSheetPaymentOptionSelect(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) {
        logPaymentSheetEvent(event: paymentSheetPaymentOptionSelectEventValue(
                                isCustom: isCustom,
                                paymentMethod: paymentMethod))
    }


    // MARK: - String builders
    enum AnalyticsPaymentMethodType : String {
        case newPM = "newpm"
        case savedPM = "savedpm"
        case applePay = "applepay"
        case link = "link"
    }
    
    func paymentSheetInitEventValue(isCustom: Bool, configuration: PaymentSheet.Configuration)
        -> STPAnalyticEvent
    {
        if isCustom {
            if configuration.customer == nil && configuration.applePay == nil {
                return .mcInitCustomDefault
            }
            
            if configuration.customer != nil && configuration.applePay == nil {
                return .mcInitCustomCustomer
            }
            
            if configuration.customer == nil && configuration.applePay != nil {
                return .mcInitCustomApplePay
            }
            
            return .mcInitCustomCustomerApplePay
        } else {
            if configuration.customer == nil && configuration.applePay == nil {
                return .mcInitCompleteDefault
            }
            
            if configuration.customer != nil && configuration.applePay == nil {
                return .mcInitCompleteCustomer
            }
            
            if configuration.customer == nil && configuration.applePay != nil {
                return .mcInitCompleteApplePay
            }
            
            return .mcInitCompleteCustomerApplePay
        }
    }
    
    func paymentSheetShowEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) -> STPAnalyticEvent
    {
        if isCustom {
            switch paymentMethod {
            case .newPM:
                return .mcShowCustomNewPM
            case .savedPM:
                return .mcShowCustomSavedPM
            case .applePay:
                return .mcShowCustomApplePay
            case .link:
                return .mcShowCustomLink
            }
        } else {
            switch paymentMethod {
            case .newPM:
                return .mcShowCompleteNewPM
            case .savedPM:
                return .mcShowCompleteSavedPM
            case .applePay:
                return .mcShowCompleteApplePay
            case .link:
                return .mcShowCompleteLink
            }
        }
    }
    
    func paymentSheetPaymentEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        success: Bool
    ) -> STPAnalyticEvent
    {
        if isCustom {
            switch paymentMethod {
            case .newPM:
                return success ? .mcPaymentCustomNewPMSuccess : .mcPaymentCustomNewPMFailure
            case .savedPM:
                return success ? .mcPaymentCustomSavedPMSuccess : .mcPaymentCustomSavedPMFailure
            case .applePay:
                return success ? .mcPaymentCustomApplePaySuccess : .mcPaymentCustomApplePayFailure
            case .link:
                return success ? .mcPaymentCustomLinkSuccess : .mcPaymentCustomLinkFailure
            }
        } else {
            switch paymentMethod {
            case .newPM:
                return success ? .mcPaymentCompleteNewPMSuccess : .mcPaymentCompleteNewPMFailure
            case .savedPM:
                return success ? .mcPaymentCompleteSavedPMSuccess : .mcPaymentCompleteSavedPMFailure
            case .applePay:
                return success ? .mcPaymentCompleteApplePaySuccess : .mcPaymentCompleteApplePayFailure
            case .link:
                return success ? .mcPaymentCompleteLinkSuccess : .mcPaymentCompleteLinkFailure
            }
        }
    }
    
    func paymentSheetPaymentOptionSelectEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) -> STPAnalyticEvent
    {
        if isCustom {
            switch paymentMethod {
            case .newPM:
                return .mcOptionSelectCustomNewPM
            case .savedPM:
                return .mcOptionSelectCustomSavedPM
            case .applePay:
                return .mcOptionSelectCustomApplePay
            case .link:
                return .mcOptionSelectCustomLink
            }
        } else {
            switch paymentMethod {
            case .newPM:
                return .mcOptionSelectCompleteNewPM
            case .savedPM:
                return .mcOptionSelectCompleteSavedPM
            case .applePay:
                return .mcOptionSelectCompleteApplePay
            case .link:
                return .mcOptionSelectCompleteLink
            }
        }
    }

    // MARK: - Internal
    func logPaymentSheetEvent(
        event: STPAnalyticEvent,
        duration: TimeInterval? = nil,
        linkEnabled: Bool? = nil,
        activeLinkSession: Bool? = nil
    ) {
        var additionalParams = [:] as [String: Any]
        if isSimulatorOrTest {
            additionalParams["is_development"] = true
        }

        if let duration = duration {
            additionalParams["duration"] = duration
        }

        if let linkEnabled = linkEnabled {
            additionalParams["link_enabled"] = linkEnabled
        }

        if let activeLinkSession = activeLinkSession {
            additionalParams["active_link_session"] = activeLinkSession
        }

        let analytic = PaymentSheetAnalytic(event: event,
                                            paymentConfiguration: nil,
                                            productUsage: productUsage,
                                            additionalParams: additionalParams)
        
        log(analytic: analytic)
    }
    
    private var isSimulatorOrTest: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return NSClassFromString("XCTest") != nil
        #endif
    }
    
}

extension PaymentSheetViewController.Mode {
    var analyticsValue : STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .addingNew:
            return .newPM
        case .selectingSaved:
            return .savedPM
        }
    }
}

extension ChoosePaymentOptionViewController.Mode {
    var analyticsValue : STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .addingNew:
            return .newPM
        case .selectingSaved:
            return .savedPM
        }
    }
}

extension SavedPaymentOptionsViewController.Selection {
    var analyticsValue : STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .add:
            return .newPM
        case .saved(paymentMethod: _):
            return .savedPM
        case .applePay:
            return .applePay
        }
    }
}

extension PaymentSheet.PaymentOption {
    var analyticsValue : STPAnalyticsClient.AnalyticsPaymentMethodType {
        switch self {
        case .applePay:
            return .applePay
        case .new:
            return .newPM
        case .saved:
            return .savedPM
        case .link:
            return .link
        }
    }
}

struct PaymentSheetAnalytic: PaymentAnalytic {
    let event: STPAnalyticEvent
    let paymentConfiguration: STPPaymentConfiguration?
    let productUsage: Set<String>
    let additionalParams: [String : Any]
}
