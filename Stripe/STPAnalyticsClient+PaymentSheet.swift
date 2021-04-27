//
//  STPAnalyticsClient+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 12/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

extension STPAnalyticsClient {
    func logPaymentSheetInitialized(
        isCustom: Bool = false, configuration: PaymentSheet.Configuration
    ) {
        var payload = type(of: self).commonPayload()
        payload["event"] = paymentSheetInitEventValue(
            isCustom: isCustom, configuration: configuration)
        if isSimulatorOrTest {
            payload["is_development"] = true
        }
        logPayload(payload)
    }
    
    enum AnalyticsPaymentMethodType : String {
        case newPM = "newpm"
        case savedPM = "savedpm"
        case applePay = "applepay"
    }
    
    func logPaymentSheetPayment(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        result: PaymentSheetResult
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
        
        var payload = type(of: self).commonPayload()
        payload["event"] = paymentSheetPaymentEventValue(
            isCustom: isCustom, paymentMethod: paymentMethod, success: success)
        if isSimulatorOrTest {
            payload["is_development"] = true
        }
        logPayload(payload)
    }

    func logPaymentSheetShow(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) {
        var payload = type(of: self).commonPayload()
        payload["event"] = paymentSheetShowEventValue(
            isCustom: isCustom, paymentMethod: paymentMethod)
        if isSimulatorOrTest {
            payload["is_development"] = true
        }
        logPayload(payload)
    }
    
    func logPaymentSheetPaymentOptionSelect(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) {
        var payload = type(of: self).commonPayload()
        payload["event"] = paymentSheetPaymentOptionSelectEventValue(
            isCustom: isCustom, paymentMethod: paymentMethod)
        if isSimulatorOrTest {
            payload["is_development"] = true
        }
        logPayload(payload)
    }

    func paymentSheetInitEventValue(isCustom: Bool, configuration: PaymentSheet.Configuration)
        -> String
    {
        return [
            "mc",
            isCustom ? "custom" : "complete",
            "init",
            configuration.customer != nil ? "customer" : nil,
            configuration.applePay != nil ? "applepay" : nil,
            configuration.customer == nil && configuration.applePay == nil ? "default" : nil,
        ].compactMap({ $0 }).joined(separator: "_")
    }
    
    func paymentSheetShowEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) -> String
    {
        return [
            "mc",
            isCustom ? "custom" : "complete",
            "sheet",
            paymentMethod.rawValue,
            "show",
        ].compactMap({ $0 }).joined(separator: "_")
    }
    
    func paymentSheetPaymentEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType,
        success: Bool
    ) -> String
    {
        return [
            "mc",
            isCustom ? "custom" : "complete",
            "payment",
            paymentMethod.rawValue,
            success ? "success" : "failure"
        ].compactMap({ $0 }).joined(separator: "_")
    }
    
    func paymentSheetPaymentOptionSelectEventValue(
        isCustom: Bool,
        paymentMethod: AnalyticsPaymentMethodType
    ) -> String
    {
        return [
            "mc",
            isCustom ? "custom" : "complete",
            "paymentoption",
            paymentMethod.rawValue,
            "select"
        ].compactMap({ $0 }).joined(separator: "_")
    }

    var isSimulatorOrTest: Bool {
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
        case .new(paymentMethodParams: _, shouldSave: _):
            return .newPM
        case .saved(paymentMethod: _):
            return .savedPM
        }
    }
}
