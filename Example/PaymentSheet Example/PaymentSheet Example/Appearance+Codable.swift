//
//  AppearanceCodableExtensions.swift
//  PaymentSheet Example
//
//  Created by George Birch on 6/19/2025.
//
//  Codable extensions for PaymentSheet.Appearance to enable persistence in the playground app.
//  These extensions are only for the example app and don't affect the public API.

import Foundation
@_spi(AppearanceAPIAdditionsPreview) import StripePaymentSheet
import UIKit

// Helper for encoding/decoding UIColor
private struct CodableUIColor: Codable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
    }

    var uiColor: UIColor {
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension PaymentSheet.Appearance: Codable {
    private enum CodingKeys: String, CodingKey {
        // Top-level properties
        case cornerRadius, borderWidth, selectedBorderWidth, sheetCornerRadius
        case sectionSpacing, verticalModeRowPadding, iconStyle
        case textFieldInsets, formInsets

        // Font properties
        case fontSizeScaleFactor, fontBaseDescriptor, fontCustomHeadlineDescriptor

        // Colors properties
        case colorsPrimary, colorsBackground, colorsComponentBackground, colorsComponentBorder
        case colorsSelectedComponentBorder, colorsComponentDivider, colorsText, colorsTextSecondary
        case colorsComponentText, colorsComponentPlaceholderText, colorsIcon, colorsDanger

        // Shadow properties
        case shadowColor, shadowOpacity, shadowOffset, shadowRadius

        // Primary Button properties
        case primaryButtonBackgroundColor, primaryButtonTextColor, primaryButtonDisabledBackgroundColor
        case primaryButtonDisabledTextColor, primaryButtonSuccessBackgroundColor, primaryButtonSuccessTextColor
        case primaryButtonCornerRadius, primaryButtonBorderColor, primaryButtonBorderWidth
        case primaryButtonFontDescriptor, primaryButtonShadowColor, primaryButtonShadowOpacity
        case primaryButtonShadowOffset, primaryButtonShadowRadius, primaryButtonHeight

        // Embedded Payment Element properties
        case embeddedRowStyle, embeddedRowAdditionalInsets
        case embeddedFlatSeparatorThickness, embeddedFlatSeparatorColor, embeddedFlatSeparatorInsets
        case embeddedFlatTopSeparatorEnabled, embeddedFlatBottomSeparatorEnabled
        case embeddedFlatRadioSelectedColor, embeddedFlatRadioUnselectedColor
        case embeddedFlatCheckmarkColor, embeddedFlatDisclosureColor
        case embeddedFloatingSpacing
    }

    public init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Top-level properties
        self.cornerRadius = try container.decodeIfPresent(CGFloat.self, forKey: .cornerRadius)
        self.borderWidth = try container.decode(CGFloat.self, forKey: .borderWidth)
        self.selectedBorderWidth = try container.decodeIfPresent(CGFloat.self, forKey: .selectedBorderWidth)
        self.sheetCornerRadius = try container.decode(CGFloat.self, forKey: .sheetCornerRadius)
        self.textFieldInsets = try container.decode(NSDirectionalEdgeInsets.self, forKey: .textFieldInsets)
        self.formInsets = try container.decode(NSDirectionalEdgeInsets.self, forKey: .formInsets)
        self.sectionSpacing = try container.decode(CGFloat.self, forKey: .sectionSpacing)
        self.iconStyle = try {
            switch try container.decode(String.self, forKey: .iconStyle) {
            case "filled": .filled
            case "outlined": .outlined
            default: throw AppearanceCodableError(description: "Unknown icon style")
            }
        }()
        self.verticalModeRowPadding = try container.decode(CGFloat.self, forKey: .verticalModeRowPadding)

        // Font properties - will need to be expanded if more options are added to the playground
        self.font.sizeScaleFactor = try container.decode(CGFloat.self, forKey: .fontSizeScaleFactor)
        let fontBaseDescriptorData = try container.decode(Data.self, forKey: .fontBaseDescriptor)
        if let fontDescriptor = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIFontDescriptor.self, from: fontBaseDescriptorData) {
            self.font.base = UIFont(descriptor: fontDescriptor, size: 12)
        } else {
            throw AppearanceCodableError(description: "Failed to decode base font descriptor")
        }
        if let headlineFontDescriptorData = try container.decodeIfPresent(Data.self, forKey: .fontCustomHeadlineDescriptor) {
            if let headlineFontDescriptor = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIFontDescriptor.self, from: headlineFontDescriptorData) {
                self.font.custom.headline = UIFont(descriptor: headlineFontDescriptor, size: 12)
            } else {
                throw AppearanceCodableError(description: "Failed to decode custom headline font descriptor")
            }
        }

        // Colors properties
        self.colors.primary = try container.decode(CodableUIColor.self, forKey: .colorsPrimary).uiColor
        self.colors.background = try container.decode(CodableUIColor.self, forKey: .colorsBackground).uiColor
        self.colors.componentBackground = try container.decode(CodableUIColor.self, forKey: .colorsComponentBackground).uiColor
        self.colors.componentBorder = try container.decode(CodableUIColor.self, forKey: .colorsComponentBorder).uiColor
        if let selectedBorder = try container.decodeIfPresent(CodableUIColor.self, forKey: .colorsSelectedComponentBorder) {
            self.colors.selectedComponentBorder = selectedBorder.uiColor
        }
        self.colors.componentDivider = try container.decode(CodableUIColor.self, forKey: .colorsComponentDivider).uiColor
        self.colors.text = try container.decode(CodableUIColor.self, forKey: .colorsText).uiColor
        self.colors.textSecondary = try container.decode(CodableUIColor.self, forKey: .colorsTextSecondary).uiColor
        self.colors.componentText = try container.decode(CodableUIColor.self, forKey: .colorsComponentText).uiColor
        self.colors.componentPlaceholderText = try container.decode(CodableUIColor.self, forKey: .colorsComponentPlaceholderText).uiColor
        self.colors.icon = try container.decode(CodableUIColor.self, forKey: .colorsIcon).uiColor
        self.colors.danger = try container.decode(CodableUIColor.self, forKey: .colorsDanger).uiColor

        // Shadow properties
        self.shadow.color = try container.decode(CodableUIColor.self, forKey: .shadowColor).uiColor
        self.shadow.opacity = try container.decode(CGFloat.self, forKey: .shadowOpacity)
        self.shadow.offset = try container.decode(CGSize.self, forKey: .shadowOffset)
        self.shadow.radius = try container.decode(CGFloat.self, forKey: .shadowRadius)

        // Primary Button properties
        if let bgColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .primaryButtonBackgroundColor) {
            self.primaryButton.backgroundColor = bgColor.uiColor
        }
        if let txtColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .primaryButtonTextColor) {
            self.primaryButton.textColor = txtColor.uiColor
        }
        if let disabledBgColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .primaryButtonDisabledBackgroundColor) {
            self.primaryButton.disabledBackgroundColor = disabledBgColor.uiColor
        }
        if let disabledTxtColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .primaryButtonDisabledTextColor) {
            self.primaryButton.disabledTextColor = disabledTxtColor.uiColor
        }
        self.primaryButton.successBackgroundColor = try container.decode(CodableUIColor.self, forKey: .primaryButtonSuccessBackgroundColor).uiColor
        if let successTxtColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .primaryButtonSuccessTextColor) {
            self.primaryButton.successTextColor = successTxtColor.uiColor
        }
        self.primaryButton.cornerRadius = try container.decodeIfPresent(CGFloat.self, forKey: .primaryButtonCornerRadius)
        self.primaryButton.borderColor = try container.decode(CodableUIColor.self, forKey: .primaryButtonBorderColor).uiColor
        self.primaryButton.borderWidth = try container.decode(CGFloat.self, forKey: .primaryButtonBorderWidth)

        if let primaryButtonFontDescriptorData = try container.decodeIfPresent(Data.self, forKey: .primaryButtonFontDescriptor) {
            if let primaryButtonFontDescriptor = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIFontDescriptor.self, from: primaryButtonFontDescriptorData) {
                self.primaryButton.font = UIFont(descriptor: primaryButtonFontDescriptor, size: 12)
            } else {
                throw AppearanceCodableError(description: "Failed to decode primary button font descriptor")
            }
        }

        // Primary Button Shadow
        if let shadowColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .primaryButtonShadowColor),
           let shadowOpacity = try container.decodeIfPresent(CGFloat.self, forKey: .primaryButtonShadowOpacity),
           let shadowOffset = try container.decodeIfPresent(CGSize.self, forKey: .primaryButtonShadowOffset),
           let shadowRadius = try container.decodeIfPresent(CGFloat.self, forKey: .primaryButtonShadowRadius) {
            self.primaryButton.shadow = PaymentSheet.Appearance.Shadow(
                color: shadowColor.uiColor,
                opacity: shadowOpacity,
                offset: shadowOffset,
                radius: shadowRadius
            )
        }
        self.primaryButton.height = try container.decode(CGFloat.self, forKey: .primaryButtonHeight)

        // Embedded Payment Element properties
        let embeddedRowStyleString = try container.decode(String.self, forKey: .embeddedRowStyle)
        switch embeddedRowStyleString {
        case "floatingButton":
            self.embeddedPaymentElement.row.style = .floatingButton
        case "flatWithCheckmark":
            self.embeddedPaymentElement.row.style = .flatWithCheckmark
        case "flatWithDisclosure":
            self.embeddedPaymentElement.row.style = .flatWithDisclosure
        default:
            self.embeddedPaymentElement.row.style = .flatWithRadio
        }

        self.embeddedPaymentElement.row.additionalInsets = try container.decode(CGFloat.self, forKey: .embeddedRowAdditionalInsets)

        // Embedded Flat properties
        self.embeddedPaymentElement.row.flat.separatorThickness = try container.decode(CGFloat.self, forKey: .embeddedFlatSeparatorThickness)
        if let sepColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .embeddedFlatSeparatorColor) {
            self.embeddedPaymentElement.row.flat.separatorColor = sepColor.uiColor
        }
        self.embeddedPaymentElement.row.flat.separatorInsets = try container.decodeIfPresent(UIEdgeInsets.self, forKey: .embeddedFlatSeparatorInsets)
        self.embeddedPaymentElement.row.flat.topSeparatorEnabled = try container.decode(Bool.self, forKey: .embeddedFlatTopSeparatorEnabled)
        self.embeddedPaymentElement.row.flat.bottomSeparatorEnabled = try container.decode(Bool.self, forKey: .embeddedFlatBottomSeparatorEnabled)

        // Radio colors
        if let selectedColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .embeddedFlatRadioSelectedColor) {
            self.embeddedPaymentElement.row.flat.radio.selectedColor = selectedColor.uiColor
        }
        if let unselectedColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .embeddedFlatRadioUnselectedColor) {
            self.embeddedPaymentElement.row.flat.radio.unselectedColor = unselectedColor.uiColor
        }

        // Checkmark and chevron colors
        if let checkmarkColor = try container.decodeIfPresent(CodableUIColor.self, forKey: .embeddedFlatCheckmarkColor) {
            self.embeddedPaymentElement.row.flat.checkmark.color = checkmarkColor.uiColor
        }
        self.embeddedPaymentElement.row.flat.disclosure.color = try container.decode(CodableUIColor.self, forKey: .embeddedFlatDisclosureColor).uiColor

        // Floating properties
        self.embeddedPaymentElement.row.floating.spacing = try container.decode(CGFloat.self, forKey: .embeddedFloatingSpacing)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Top-level properties
        try container.encode(cornerRadius, forKey: .cornerRadius)
        try container.encode(borderWidth, forKey: .borderWidth)
        try container.encodeIfPresent(selectedBorderWidth, forKey: .selectedBorderWidth)
        try container.encode(sheetCornerRadius, forKey: .sheetCornerRadius)
        try container.encode(sectionSpacing, forKey: .sectionSpacing)
        try container.encode(verticalModeRowPadding, forKey: .verticalModeRowPadding)

        let iconStyleString =
        switch iconStyle {
        case .filled: "filled"
        case .outlined: "outlined"
        default: throw AppearanceCodableError(description: "Unknown icon style")
        }
        try container.encode(iconStyleString, forKey: .iconStyle)

        try container.encode(textFieldInsets, forKey: .textFieldInsets)
        try container.encode(formInsets, forKey: .formInsets)

        // Font properties - will need to be expanded if more options are added to the playground
        try container.encode(font.sizeScaleFactor, forKey: .fontSizeScaleFactor)
        let fontBaseDescriptorData = try NSKeyedArchiver.archivedData(withRootObject: font.base.fontDescriptor, requiringSecureCoding: false)
        try container.encode(fontBaseDescriptorData, forKey: .fontBaseDescriptor)
        if let headline = font.custom.headline {
            let headlineFontDescriptorData = try NSKeyedArchiver.archivedData(withRootObject: headline.fontDescriptor, requiringSecureCoding: false)
            try container.encode(headlineFontDescriptorData, forKey: .fontCustomHeadlineDescriptor)
        }

        // Colors properties
        try container.encode(CodableUIColor(color: colors.primary), forKey: .colorsPrimary)
        try container.encode(CodableUIColor(color: colors.background), forKey: .colorsBackground)
        try container.encode(CodableUIColor(color: colors.componentBackground), forKey: .colorsComponentBackground)
        try container.encode(CodableUIColor(color: colors.componentBorder), forKey: .colorsComponentBorder)
        if let selectedComponentBorder = colors.selectedComponentBorder {
            try container.encode(CodableUIColor(color: selectedComponentBorder), forKey: .colorsSelectedComponentBorder)
        }
        try container.encode(CodableUIColor(color: colors.componentDivider), forKey: .colorsComponentDivider)
        try container.encode(CodableUIColor(color: colors.text), forKey: .colorsText)
        try container.encode(CodableUIColor(color: colors.textSecondary), forKey: .colorsTextSecondary)
        try container.encode(CodableUIColor(color: colors.componentText), forKey: .colorsComponentText)
        try container.encode(CodableUIColor(color: colors.componentPlaceholderText), forKey: .colorsComponentPlaceholderText)
        try container.encode(CodableUIColor(color: colors.icon), forKey: .colorsIcon)
        try container.encode(CodableUIColor(color: colors.danger), forKey: .colorsDanger)

        // Shadow properties
        try container.encode(CodableUIColor(color: shadow.color), forKey: .shadowColor)
        try container.encode(shadow.opacity, forKey: .shadowOpacity)
        try container.encode(shadow.offset, forKey: .shadowOffset)
        try container.encode(shadow.radius, forKey: .shadowRadius)

        // Primary Button properties
        if let backgroundColor = primaryButton.backgroundColor {
            try container.encode(CodableUIColor(color: backgroundColor), forKey: .primaryButtonBackgroundColor)
        }
        if let textColor = primaryButton.textColor {
            try container.encode(CodableUIColor(color: textColor), forKey: .primaryButtonTextColor)
        }
        if let disabledBackgroundColor = primaryButton.disabledBackgroundColor {
            try container.encode(CodableUIColor(color: disabledBackgroundColor), forKey: .primaryButtonDisabledBackgroundColor)
        }
        if let disabledTextColor = primaryButton.disabledTextColor {
            try container.encode(CodableUIColor(color: disabledTextColor), forKey: .primaryButtonDisabledTextColor)
        }
        try container.encode(CodableUIColor(color: primaryButton.successBackgroundColor), forKey: .primaryButtonSuccessBackgroundColor)
        if let successTextColor = primaryButton.successTextColor {
            try container.encode(CodableUIColor(color: successTextColor), forKey: .primaryButtonSuccessTextColor)
        }
        try container.encodeIfPresent(primaryButton.cornerRadius, forKey: .primaryButtonCornerRadius)
        try container.encode(CodableUIColor(color: primaryButton.borderColor), forKey: .primaryButtonBorderColor)
        try container.encode(primaryButton.borderWidth, forKey: .primaryButtonBorderWidth)
        if let font = primaryButton.font {
            let primaryButtonFontDescriptorData = try NSKeyedArchiver.archivedData(withRootObject: font.fontDescriptor, requiringSecureCoding: false)
            try container.encode(primaryButtonFontDescriptorData, forKey: .primaryButtonFontDescriptor)
        }

        // Primary Button Shadow
        if let shadow = primaryButton.shadow {
            try container.encode(CodableUIColor(color: shadow.color), forKey: .primaryButtonShadowColor)
            try container.encode(shadow.opacity, forKey: .primaryButtonShadowOpacity)
            try container.encode(shadow.offset, forKey: .primaryButtonShadowOffset)
            try container.encode(shadow.radius, forKey: .primaryButtonShadowRadius)
        }
        try container.encode(primaryButton.height, forKey: .primaryButtonHeight)

        // Embedded Payment Element properties
        let embeddedRowStyleString: String
        switch embeddedPaymentElement.row.style {
        case .flatWithRadio:
            embeddedRowStyleString = "flatWithRadio"
        case .floatingButton:
            embeddedRowStyleString = "floatingButton"
        case .flatWithCheckmark:
            embeddedRowStyleString = "flatWithCheckmark"
        case .flatWithDisclosure:
            embeddedRowStyleString = "flatWithDisclosure"
        default:
            throw AppearanceCodableError(description: "Implement encoding for new row styles in AppearanceCodableExtensions.swift")
        }
        try container.encode(embeddedRowStyleString, forKey: .embeddedRowStyle)
        try container.encode(embeddedPaymentElement.row.additionalInsets, forKey: .embeddedRowAdditionalInsets)

        // Embedded Flat properties
        try container.encode(embeddedPaymentElement.row.flat.separatorThickness, forKey: .embeddedFlatSeparatorThickness)
        if let separatorColor = embeddedPaymentElement.row.flat.separatorColor {
            try container.encode(CodableUIColor(color: separatorColor), forKey: .embeddedFlatSeparatorColor)
        }
        try container.encodeIfPresent(embeddedPaymentElement.row.flat.separatorInsets, forKey: .embeddedFlatSeparatorInsets)
        try container.encode(embeddedPaymentElement.row.flat.topSeparatorEnabled, forKey: .embeddedFlatTopSeparatorEnabled)
        try container.encode(embeddedPaymentElement.row.flat.bottomSeparatorEnabled, forKey: .embeddedFlatBottomSeparatorEnabled)

        // Radio colors
        if let selectedColor = embeddedPaymentElement.row.flat.radio.selectedColor {
            try container.encode(CodableUIColor(color: selectedColor), forKey: .embeddedFlatRadioSelectedColor)
        }
        if let unselectedColor = embeddedPaymentElement.row.flat.radio.unselectedColor {
            try container.encode(CodableUIColor(color: unselectedColor), forKey: .embeddedFlatRadioUnselectedColor)
        }

        // Checkmark and chevron colors
        if let checkmarkColor = embeddedPaymentElement.row.flat.checkmark.color {
            try container.encode(CodableUIColor(color: checkmarkColor), forKey: .embeddedFlatCheckmarkColor)
        }
        try container.encode(CodableUIColor(color: embeddedPaymentElement.row.flat.disclosure.color), forKey: .embeddedFlatDisclosureColor)

        // Floating properties
        try container.encode(embeddedPaymentElement.row.floating.spacing, forKey: .embeddedFloatingSpacing)
    }
}

private struct AppearanceCodableError: Error {
    let description: String
}
