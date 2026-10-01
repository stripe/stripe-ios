//
//  SheetImplementationResolver.swift
//  StripePaymentSheet
//
//  Created by George Birch on 9/30/26.
//

import UIKit

/// Captures the rollout decision for one FlowController or Embedded Payment Element instance.
/// Retains the initial assignment across Elements Session updates so presentation does not switch mid-flow.
final class SheetImplementationResolver {

    static let isRequiredForDevice: Bool = {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        // Use the hardware model rather than size classes, which change when Duo folds or unfolds.
        let modelIdentifier: String
        #if targetEnvironment(simulator)
        modelIdentifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        modelIdentifier = Mirror(reflecting: systemInfo.machine).children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        #endif
        // iPhone Duo needs native presentation in both folded and unfolded states.
        return modelIdentifier == "iPhone19,4"
        #else
        return false
        #endif
    }()

    private let isEnabled: Bool
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private let experiment: NativeSheetExperiment?
    private var exposureLogged = false

    @MainActor
    var usesNativeSheet: Bool {
        // Forced-native devices must not be counted in the experiment's control group.
        if Self.isRequiredForDevice {
            return true
        }
        guard isEnabled, UIDevice.current.userInterfaceIdiom == .phone else {
            return false
        }
        // Log exposure immediately before reading the assignment, at most once for this flow.
        if let experiment, !exposureLogged {
            analyticsHelper.logExposure(experiment: experiment)
            exposureLogged = true
        }
        return experiment?.group == .treatment
    }

    init(elementsSession: STPElementsSession, analyticsHelper: PaymentSheetAnalyticsHelper, integrationShape: String) {
        isEnabled = elementsSession.isNativeSheetEnabled
        experiment = NativeSheetExperiment(elementsSession: elementsSession, integrationShape: integrationShape)
        self.analyticsHelper = analyticsHelper
    }
}
