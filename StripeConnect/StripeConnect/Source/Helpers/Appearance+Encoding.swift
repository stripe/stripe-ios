//
//  Appearance+Encoding.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/4/24.
//

@_spi(STP) import StripeCore
import UIKit

@available(iOS 15, *)
typealias Appearance = EmbeddedComponentManager.Appearance

@available(iOS 15, *)
extension Appearance {
    func asDictionary(traitCollection: UITraitCollection) -> [String: String] {
        var dict: [String: String] = [:]

        dict.mergeAssertingOnOverwrites(colors.asDictionary(traitCollection: traitCollection))
        dict.mergeAssertingOnOverwrites(typography.asDictionary(traitCollection: traitCollection))
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

@available(iOS 15, *)
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

@available(iOS 15, *)
extension Appearance.Badge {
    private func mappings(keyPrefix: String) -> [String: KeyPath<Self, UIColor?>] {
        [
            "\(keyPrefix)ColorBackground": \.colorBackground,
            "\(keyPrefix)ColorText": \.colorText,
            "\(keyPrefix)ColorBorder": \.colorBorder,
        ]
    }

    func asDictionary(keyPrefix: String) -> [String: String] {
        mappings(keyPrefix: keyPrefix).compactMapValues { self[keyPath: $0]?.cssValue(includeAlpha: false) }
    }
}

@available(iOS 15, *)
extension Appearance.Button {

    private func mappings(keyPrefix: String) -> [String: KeyPath<Self, UIColor?>] {
        [
            "\(keyPrefix)ColorBackground": \.colorBackground,
            "\(keyPrefix)ColorText": \.colorText,
            "\(keyPrefix)ColorBorder": \.colorBorder,
        ]
    }

    func asDictionary(keyPrefix: String) -> [String: String] {
        mappings(keyPrefix: keyPrefix).compactMapValues { self[keyPath: $0]?.cssValue(includeAlpha: false) }
    }
}

@available(iOS 15, *)
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
            "formHighlightColorBorder": \.formHighlightBorder,
        ]
    }

    func asDictionary(traitCollection: UITraitCollection) -> [String: String] {
        mappings.compactMapValues { self[keyPath: $0]?.resolvedColor(with: traitCollection).cssRgbValue }
    }
}

@available(iOS 15, *)
extension Appearance.Typography {
    var mappings: [String: KeyPath<Self, Style>] {
        [
            "bodySm": \.bodySm,
            "bodyMd": \.bodyMd,
            "headingXs": \.headingXs,
            "headingSm": \.headingSm,
            "headingMd": \.headingMd,
            "headingLg": \.headingLg,
            "headingXl": \.headingXl,
            "labelMd": \.labelMd,
            "labelSm": \.labelSm,
        ]
    }

    func asDictionary(traitCollection: UITraitCollection) -> [String: String] {
        var dict: [String: String] = [:]

        // Default font to "-apple-system" to use the system default,
        // otherwise the webView will use Times
        dict["fontFamily"] = font?.familyName ?? "-apple-system"

        if let fontSizeBase {
            dict["fontSizeBase"] = UIFontMetrics.default.scaledValue(for: fontSizeBase, compatibleWith: traitCollection).pxString
        }

        mappings.forEach { (key, keyPath) in
            dict.mergeAssertingOnOverwrites(self[keyPath: keyPath].asDictionary(
                keyPrefix: key,
                using: traitCollection))
        }

        return dict
    }
}

@available(iOS 15, *)
extension Appearance.Typography.Style {
    func asDictionary(
        keyPrefix: String,
        using traitCollection: UITraitCollection
    ) -> [String: String] {
        var dict: [String: String] = [:]

        if let fontSize {
            dict["\(keyPrefix)FontSize"] = UIFontMetrics.default.scaledValue(for: fontSize, compatibleWith: traitCollection).pxString
        }
        dict["\(keyPrefix)FontWeight"] = weight?.cssValue
        dict["\(keyPrefix)TextTransform"] = textTransform?.rawValue
        return dict
    }
}
