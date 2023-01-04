//
//  STPThreeDSSelectionCustomization.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

#if canImport(Stripe3DS2)
    import Stripe3DS2
#endif

/// A customization object that configures the appearance of
/// radio buttons and checkboxes.
public class STPThreeDSSelectionCustomization: NSObject {
    /// The default settings.
    @objc
    public class func defaultSettings() -> STPThreeDSSelectionCustomization {
        return STPThreeDSSelectionCustomization()
    }

    internal var selectionCustomization = STDSSelectionCustomization.defaultSettings()

    /// The primary color of the selected state.
    /// Defaults to blue.

    @objc public var primarySelectedColor: UIColor {
        get {
            return selectionCustomization.primarySelectedColor
        }
        set(primarySelectedColor) {
            selectionCustomization.primarySelectedColor = primarySelectedColor
        }
    }
    /// The secondary color of the selected state (e.g. the checkmark color).
    /// Defaults to white.

    @objc public var secondarySelectedColor: UIColor {
        get {
            return selectionCustomization.secondarySelectedColor
        }
        set(secondarySelectedColor) {
            selectionCustomization.secondarySelectedColor = secondarySelectedColor
        }
    }
    /// The background color displayed in the unselected state.
    /// Defaults to light blue.

    @objc public var unselectedBackgroundColor: UIColor {
        get {
            return selectionCustomization.unselectedBackgroundColor
        }
        set(unselectedBackgroundColor) {
            selectionCustomization.unselectedBackgroundColor = unselectedBackgroundColor
        }
    }
    /// The color of the border drawn around the view in the unselected state.
    /// Defaults to blue.

    @objc public var unselectedBorderColor: UIColor {
        get {
            return selectionCustomization.unselectedBorderColor
        }
        set(unselectedBorderColor) {
            selectionCustomization.unselectedBorderColor = unselectedBorderColor
        }
    }

}
