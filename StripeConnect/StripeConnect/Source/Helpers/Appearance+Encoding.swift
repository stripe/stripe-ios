//
//  Appearance+Encoding.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/4/24.
//

@_spi(STP) import StripeCore
import UIKit

typealias Appearance = EmbeddedComponentManager.Appearance

extension Appearance {
    func asDictionary(traitCollection: UITraitCollection) -> [String: String] {
        var dict: [String: String] = [:]
        
        dict.mergeAssertingOnOverwrites(colors.asDictionary(traitCollection: traitCollection))
        dict.mergeAssertingOnOverwrites(typography.asDictionary())
        dict.mergeAssertingOnOverwrites(buttonPrimary.asDictionary(keyPrefix: "buttonPrimary"))
        dict.mergeAssertingOnOverwrites(buttonSecondary.asDictionary(keyPrefix: "buttonSecondary"))
        dict.mergeAssertingOnOverwrites(badgeNeutral.asDictionary(keyPrefix: "badgeNeutral"))
        dict.mergeAssertingOnOverwrites(badgeSuccess.asDictionary(keyPrefix: "badgeSuccess"))
        dict.mergeAssertingOnOverwrites(badgeWarning.asDictionary(keyPrefix: "badgeWarning"))
        dict.mergeAssertingOnOverwrites(badgeDanger.asDictionary(keyPrefix: "badgeDanger"))
        dict.mergeAssertingOnOverwrites(cornerRadius.asDictionary())
        
        dict["spacingUnit"] = spacingUnit?.pxString
        
        return dict
    }
}

extension Appearance.CornerRadius {
    private var mappings: [String: KeyPath<Self, CGFloat?>] {
        [
            "borderRadius": \.base,
            "buttonBorderRadius": \.button,
            "formBorderRadius": \.form,
            "badgeBorderRadius": \.badge,
            "overlayBorderRadius": \.overlay,
        ]
    }
    
    func asDictionary() -> [String: String] {
        mappings.compactMapValues { self[keyPath: $0]?.pxString }
    }
}

extension Appearance.Badge {
    private func mappings(keyPrefix: String) -> [String: KeyPath<Self, UIColor?>] {
        [
            "\(keyPrefix)ColorBackground": \.colorBackground,
            "\(keyPrefix)ColorText": \.colorText,
            "\(keyPrefix)ColorBorder": \.colorBorder
        ]
    }
    
    func asDictionary(keyPrefix: String) -> [String: String] {
        mappings(keyPrefix: keyPrefix).compactMapValues { self[keyPath: $0]?.cssValue(includeAlpha: false) }
    }
}

extension Appearance.Button {
    
    private func mappings(keyPrefix: String) -> [String: KeyPath<Self, UIColor?>] {
        [
            "\(keyPrefix)ColorBackground": \.colorBackground,
            "\(keyPrefix)ColorText": \.colorText,
            "\(keyPrefix)ColorBorder": \.colorBorder
        ]
    }
    
    func asDictionary(keyPrefix: String) -> [String: String] {
        mappings(keyPrefix: keyPrefix).compactMapValues { self[keyPath: $0]?.cssValue(includeAlpha: false) }
    }
}

extension Appearance.Colors {
    var mappings: [String: KeyPath<Self, UIColor?>] {
        [
            "formAccentColor": \.formAccent,
            "colorPrimary": \.primary,
            "colorBackground": \.background,
            "colorText": \.text,
            "colorDanger": \.danger,
            "actionPrimaryColorText": \.actionPrimaryText,
            "actionSecondaryColorText": \.actionSecondaryText,
            "offsetBackgroundColor": \.offsetBackground,
            "formBackgroundColor": \.formBackground,
            "colorSecondaryText": \.secondaryText,
            "colorBorder": \.border,
            "formHighlightColorBorder": \.formHighlightBorder
        ]
    }
    
    func asDictionary(traitCollection: UITraitCollection) -> [String: String] {
        mappings.compactMapValues { self[keyPath: $0]?.resolvedColor(with: traitCollection).cssRgbValue }
    }
}

extension Appearance.Typography {
    func asDictionary() -> [String: String] {
        var dict: [String: String] = [:]
        
        // Default font to "-apple-system" to use the system default,
        // otherwise the webView will use Times
        dict["fontFamily"] = font?.familyName ?? "-apple-system"
        
        dict["fontSizeBase"] = fontSizeBase?.pxString
        
        dict.mergeAssertingOnOverwrites(bodySm.asDictionary(keyPrefix: "bodySm"))
        dict.mergeAssertingOnOverwrites(bodyMd.asDictionary(keyPrefix: "bodyMd"))
        
        dict.mergeAssertingOnOverwrites(headingXs.asDictionary(keyPrefix: "headingXs"))
        dict.mergeAssertingOnOverwrites(headingSm.asDictionary(keyPrefix: "headingSm"))
        dict.mergeAssertingOnOverwrites(headingMd.asDictionary(keyPrefix: "headingMd"))
        dict.mergeAssertingOnOverwrites(headingLg.asDictionary(keyPrefix: "headingLg"))
        dict.mergeAssertingOnOverwrites(headingXl.asDictionary(keyPrefix: "headingXl"))
        
        dict.mergeAssertingOnOverwrites(labelMd.asDictionary(keyPrefix: "labelMd"))
        dict.mergeAssertingOnOverwrites(labelSm.asDictionary(keyPrefix: "labelSm"))
        
        return dict
    }
}

extension Appearance.Typography.Style {
    func asDictionary(keyPrefix: String) -> [String: String] {
        var dict: [String: String] = [:]
        dict["\(keyPrefix)FontSize"] = fontSize?.pxString
        dict["\(keyPrefix)FontWeight"] = weight?.cssValue
        dict["\(keyPrefix)TextTransform"] = textTransform?.rawValue
        return dict
    }
}
