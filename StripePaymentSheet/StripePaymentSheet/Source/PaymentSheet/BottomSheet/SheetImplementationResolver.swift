//
//  SheetImplementationResolver.swift
//  StripePaymentSheet
//
//  Created by George Birch on 9/30/26.
//

import UIKit

/// Captures the native-sheet feature flag for one FlowController or Embedded Payment Element instance.
/// Retains the initial decision across Elements Session updates so presentation does not switch mid-flow.
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

    @MainActor
    var usesNativeSheet: Bool {
        // iPhone Duo requires native presentation even when the feature flag is disabled.
        if Self.isRequiredForDevice {
            return true
        }
        return isEnabled && UIDevice.current.userInterfaceIdiom == .phone
    }

    init(elementsSession: STPElementsSession) {
        // Capture playground overrides per flow so changing the setting cannot switch an existing presentation.
        isEnabled = PaymentSheet.NativeSheetFeatureFlags.nativeSheetEnabledOverride ?? elementsSession.isNativeSheetEnabled
    }
}

extension PaymentSheet {

    @_spi(STP) public enum NativeSheetFeatureFlags {

        /// Whether the current device requires native sheets, regardless of the feature flag.
        @_spi(STP) public static var isNativeSheetRequiredForDevice: Bool {
            SheetImplementationResolver.isRequiredForDevice
        }

        /// Overrides the native-sheet feature flag. Intended for test playgrounds only.
        @_spi(STP) public static var nativeSheetEnabledOverride: Bool?
    }
}
