//
//  STPThreeDS2Localization.swift
//  StripeCore
//
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation

/// Stripe3DS2 strings stored in StripeCore's localization table.
@objc(STPThreeDS2Localization)
@objcMembers
@_spi(STP) public final class STPThreeDS2Localization: NSObject {
    public static var debuggerWarning: String {
        return STPLocalizedString("A debugger is attached to the App.", "The text for warning when a debugger is currently attached to the process.")
    }

    public static var emulatorWarning: String {
        return STPLocalizedString("An emulator is being used to run the App.", "The text for warning when an emulator is being used to run the application.")
    }

    public static var cancel: String {
        return String.Localized.cancel
    }

    public static var collapsed: String {
        return STPLocalizedString("Collapsed", "Accessibility label for expandable text control to indicate text is hidden.")
    }

    public static var expanded: String {
        return STPLocalizedString("Expanded", "Accessibility label for expandable text control to indicate that the UI has been expanded and additional text is available.")
    }

    public static var loading: String {
        return String.Localized.loading
    }

    public static var no: String {
        return STPLocalizedString("No", "The no answer to a yes or no question.")
    }

    public static var secureCheckout: String {
        return STPLocalizedString("Secure checkout", "The title for the challenge response step of an authenticated checkout.")
    }

    public static var selected: String {
        return STPLocalizedString("Selected", "Indicates that a button is selected.")
    }

    public static var unsupportedOSWarning: String {
        return STPLocalizedString("The OS or the OS Version is not supported.", "The text for warning when the SDK is running on an unsupported OS or OS version.")
    }

    public static var jailbrokenWarning: String {
        return STPLocalizedString("The device is jailbroken.", "The text for warning when a device is jailbroken.")
    }

    public static var tamperedWarning: String {
        return STPLocalizedString("The integrity of the SDK has been tampered.", "The text for warning when the integrity of the SDK has been tampered with.")
    }

    public static var timeout: String {
        return STPLocalizedString("Timeout", "Error description for when a network request times out. English value is as required by UL certification.")
    }

    public static var unselected: String {
        return STPLocalizedString("Unselected", "Indicates that a button is not selected.")
    }

    public static var yes: String {
        return STPLocalizedString("Yes", "The yes answer to a yes or no question.")
    }
}
