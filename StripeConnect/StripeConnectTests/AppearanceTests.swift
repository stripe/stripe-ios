//
//  AppearanceTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 9/4/24.
//

@_spi(PrivateBetaConnect) @testable import StripeConnect
import UIKit
import XCTest

class AppearanceTests: XCTestCase {
    typealias Appearance = EmbeddedComponentManager.Appearance

    let testAppearance: Appearance = {
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.typography.font = UIFont(name: "Helvetica", size: 16)
        appearance.typography.fontSizeBase = 16
        appearance.typography.bodyMd.fontSize = 16
        appearance.typography.bodyMd.weight = .regular
        appearance.typography.bodyMd.textTransform = EmbeddedComponentManager.Appearance.TextTransform.none
        appearance.typography.bodySm.fontSize = 14
        appearance.typography.bodySm.weight = .light
        appearance.typography.bodySm.textTransform = .lowercase
        appearance.typography.headingXl.fontSize = 28
        appearance.typography.headingXl.weight = .bold
        appearance.typography.headingXl.textTransform = .uppercase
        appearance.typography.headingLg.fontSize = 24
        appearance.typography.headingLg.weight = .semibold
        appearance.typography.headingLg.textTransform = .capitalize
        appearance.typography.headingMd.fontSize = 20
        appearance.typography.headingMd.weight = .medium
        appearance.typography.headingSm.fontSize = 18
        appearance.typography.headingSm.weight = .regular
        appearance.typography.headingXs.fontSize = 16
        appearance.typography.headingXs.weight = .light
        appearance.typography.labelMd.fontSize = 14
        appearance.typography.labelMd.weight = .medium
        appearance.typography.labelSm.fontSize = 12
        appearance.typography.labelSm.weight = .regular

        appearance.colors.primary = UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0)
        appearance.colors.text = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1.0)
        appearance.colors.danger = UIColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0)
        appearance.colors.background = UIColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1.0)
        appearance.colors.secondaryText = UIColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 1.0)
        appearance.colors.border = UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1.0)
        appearance.colors.actionPrimaryText = UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0)
        appearance.colors.actionSecondaryText = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        appearance.colors.offsetBackground = UIColor(red: 0.9, green: 1.0, blue: 0.1, alpha: 1.0)
        appearance.colors.formBackground = UIColor(red: 1.0, green: 0.1, blue: 0.2, alpha: 1.0)
        appearance.colors.formHighlightBorder = UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.5)
        appearance.colors.formAccent = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1.0)

        appearance.spacingUnit = 8

        appearance.buttonPrimary.colorBackground = UIColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0)
        appearance.buttonPrimary.colorBorder = UIColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1.0)
        appearance.buttonPrimary.colorText = UIColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 1.0)

        appearance.buttonSecondary.colorBackground = UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1.0)
        appearance.buttonSecondary.colorBorder = UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0)
        appearance.buttonSecondary.colorText = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)

        appearance.badgeNeutral.colorBackground = UIColor(red: 0.9, green: 1.0, blue: 0.1, alpha: 1.0)
        appearance.badgeNeutral.colorText = UIColor(red: 1.0, green: 0.1, blue: 0.2, alpha: 1.0)
        appearance.badgeNeutral.colorBorder = UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1.0)

        appearance.badgeSuccess.colorBackground = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1.0)
        appearance.badgeSuccess.colorText = UIColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0)
        appearance.badgeSuccess.colorBorder = UIColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1.0)

        appearance.badgeWarning.colorBackground = UIColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 1.0)
        appearance.badgeWarning.colorText = UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1.0)
        appearance.badgeWarning.colorBorder = UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 1.0)

        appearance.badgeDanger.colorBackground = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        appearance.badgeDanger.colorText = UIColor(red: 0.9, green: 1.0, blue: 0.1, alpha: 1.0)
        appearance.badgeDanger.colorBorder = UIColor(red: 1.0, green: 0.1, blue: 0.2, alpha: 1.0)

        appearance.cornerRadius.base = 4
        appearance.cornerRadius.form = 6
        appearance.cornerRadius.button = 8
        appearance.cornerRadius.badge = 10
        appearance.cornerRadius.overlay = 12
        return appearance
    }()

    func testAllFieldsAreFilledWithCorrectValuesInDictionary() {
        let actualValues = testAppearance.asDictionary(traitCollection: .init())
        let expectedValues: [String: String] = [
            "fontFamily": "Helvetica",
            "fontSizeBase": "16px",
            "bodyMdFontSize": "16px",
            "bodyMdFontWeight": "400",
            "bodyMdTextTransform": "none",
            "bodySmFontSize": "14px",
            "bodySmFontWeight": "300",
            "bodySmTextTransform": "lowercase",
            "headingXlFontSize": "28px",
            "headingXlFontWeight": "700",
            "headingXlTextTransform": "uppercase",
            "headingLgFontSize": "24px",
            "headingLgFontWeight": "600",
            "headingLgTextTransform": "capitalize",
            "headingMdFontSize": "20px",
            "headingMdFontWeight": "500",
            "headingSmFontSize": "18px",
            "headingSmFontWeight": "400",
            "headingXsFontSize": "16px",
            "headingXsFontWeight": "300",
            "labelMdFontSize": "14px",
            "labelMdFontWeight": "500",
            "labelSmFontSize": "12px",
            "labelSmFontWeight": "400",
            "formAccentColor": "rgb(51, 76, 102)",
            "colorPrimary": "rgb(26, 51, 76)",
            "colorBackground": "rgb(102, 128, 153)",
            "colorText": "rgb(51, 76, 102)",
            "colorDanger": "rgb(76, 102, 128)",
            "actionPrimaryColorText": "rgb(178, 204, 230)",
            "actionSecondaryColorText": "rgb(204, 230, 255)",
            "offsetBackgroundColor": "rgb(230, 255, 26)",
            "formBackgroundColor": "rgb(255, 26, 51)",
            "colorSecondaryText": "rgb(128, 153, 178)",
            "colorBorder": "rgb(153, 178, 204)",
            "formHighlightColorBorder": "rgb(26, 51, 76)",
            "spacingUnit": "8px",
            "buttonPrimaryColorBackground": "rgb(76, 102, 128)",
            "buttonPrimaryColorBorder": "rgb(102, 128, 153)",
            "buttonPrimaryColorText": "rgb(128, 153, 178)",
            "buttonSecondaryColorBackground": "rgb(153, 178, 204)",
            "buttonSecondaryColorBorder": "rgb(178, 204, 230)",
            "buttonSecondaryColorText": "rgb(204, 230, 255)",
            "badgeNeutralColorBackground": "rgb(230, 255, 26)",
            "badgeNeutralColorText": "rgb(255, 26, 51)",
            "badgeNeutralColorBorder": "rgb(26, 51, 76)",
            "badgeSuccessColorBackground": "rgb(51, 76, 102)",
            "badgeSuccessColorText": "rgb(76, 102, 128)",
            "badgeSuccessColorBorder": "rgb(102, 128, 153)",
            "badgeWarningColorBackground": "rgb(128, 153, 178)",
            "badgeWarningColorText": "rgb(153, 178, 204)",
            "badgeWarningColorBorder": "rgb(178, 204, 230)",
            "badgeDangerColorBackground": "rgb(204, 230, 255)",
            "badgeDangerColorText": "rgb(230, 255, 26)",
            "badgeDangerColorBorder": "rgb(255, 26, 51)",
            "borderRadius": "4px",
            "buttonBorderRadius": "8px",
            "formBorderRadius": "6px",
            "badgeBorderRadius": "10px",
            "overlayBorderRadius": "12px",
        ]

        XCTAssertEqual(actualValues, expectedValues)
    }

    func testDefaultAppearance() {
        let appearance: Appearance = .default
        XCTAssertEqual(appearance.asDictionary(traitCollection: .init()), [
            "fontFamily": "-apple-system",
            "fontSizeBase": "16px",
        ])
    }

    func testColorsChangeBasedOnTraitCollection() {
        var appearance: Appearance = .default

        appearance.colors.actionPrimaryText = UIColor { $0.userInterfaceStyle == .light ? .red : .green }
        appearance.colors.background = UIColor { $0.userInterfaceStyle == .light ? .white : .black }
        appearance.colors.text = UIColor { $0.userInterfaceStyle == .light ? .black : .white }

        let lightModeTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkModeTraits =  UITraitCollection(userInterfaceStyle: .dark)

        XCTAssertEqual(appearance.asDictionary(traitCollection: lightModeTraits)["actionPrimaryColorText"], "rgb(255, 0, 0)")
        XCTAssertEqual(appearance.asDictionary(traitCollection: darkModeTraits)["actionPrimaryColorText"], "rgb(0, 255, 0)")

        XCTAssertEqual(appearance.asDictionary(traitCollection: lightModeTraits)["colorBackground"], "rgb(255, 255, 255)")
        XCTAssertEqual(appearance.asDictionary(traitCollection: darkModeTraits)["colorBackground"], "rgb(0, 0, 0)")

        XCTAssertEqual(appearance.asDictionary(traitCollection: lightModeTraits)["colorText"], "rgb(0, 0, 0)")
        XCTAssertEqual(appearance.asDictionary(traitCollection: darkModeTraits)["colorText"], "rgb(255, 255, 255)")
    }

    func testFontSizesChangeBasedOnTraitCollection() {
        var appearance = Appearance.default

        appearance.typography.fontSizeBase = 16
        appearance.typography.headingLg.fontSize = 32

        let xsFontDict = appearance.asDictionary(traitCollection: UITraitCollection(preferredContentSizeCategory: .extraSmall))
        let axxxlDict = appearance.asDictionary(traitCollection: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))

        XCTAssertEqual(xsFontDict["fontSizeBase"], "13px")
        XCTAssertEqual(xsFontDict["headingLgFontSize"], "27px")
        XCTAssertEqual(axxxlDict["fontSizeBase"], "45px")
        XCTAssertEqual(axxxlDict["headingLgFontSize"], "90px")
    }
}
