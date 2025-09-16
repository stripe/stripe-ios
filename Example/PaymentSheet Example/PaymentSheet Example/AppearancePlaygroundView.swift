//
//  AppearancePlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/1/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

@_spi(AppearanceAPIAdditionsPreview)@_spi(STP) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

@available(iOS 14.0, *)
struct AppearancePlaygroundView: View {
    @State var appearance: PaymentSheet.Appearance
    var doneAction: ((PaymentSheet.Appearance) -> Void) = { _ in }

    init(appearance: PaymentSheet.Appearance, doneAction: @escaping ((PaymentSheet.Appearance) -> Void)) {
        _appearance = State<PaymentSheet.Appearance>.init(initialValue: appearance)
        self.doneAction = doneAction
    }
    static let fonts = ["System Default", "AvenirNext-Regular", "PingFangHK-Regular", "ChalkboardSE-Light"]

    var body: some View {
        let primaryColorBinding = Binding(
            get: { Color(self.appearance.colors.primary) },
            set: { self.appearance.colors.primary = UIColor($0) }
        )

        let backgroundColorBinding = Binding(
            get: { Color(self.appearance.colors.background) },
            set: { self.appearance.colors.background = UIColor($0) }
        )

        let componentBackgroundColorBinding = Binding(
            get: { Color(self.appearance.colors.componentBackground) },
            set: { self.appearance.colors.componentBackground = UIColor($0) }
        )

        let componentBorderColorBinding = Binding(
            get: { Color(self.appearance.colors.componentBorder) },
            set: { self.appearance.colors.componentBorder = UIColor($0) }
        )

        let selectedComponentBorderColorBinding = Binding(
            get: { Color(self.appearance.colors.selectedComponentBorder ?? self.appearance.colors.primary) },
            set: { self.appearance.colors.selectedComponentBorder = UIColor($0) }
        )

        let componentDividerColorBinding = Binding(
            get: { Color(self.appearance.colors.componentDivider) },
            set: { self.appearance.colors.componentDivider = UIColor($0) }
        )

        let textColorBinding = Binding(
            get: { Color(self.appearance.colors.text) },
            set: { self.appearance.colors.text = UIColor($0) }
        )

        let textSecondaryColorBinding = Binding(
            get: { Color(self.appearance.colors.textSecondary) },
            set: { self.appearance.colors.textSecondary = UIColor($0) }
        )

        let componentBackgroundTextColorBinding = Binding(
            get: { Color(self.appearance.colors.componentText) },
            set: { self.appearance.colors.componentText = UIColor($0) }
        )

        let placeholderTextColorBinding = Binding(
            get: { Color(self.appearance.colors.componentPlaceholderText) },
            set: { self.appearance.colors.componentPlaceholderText = UIColor($0) }
        )

        let iconColorBinding = Binding(
            get: { Color(self.appearance.colors.icon) },
            set: { self.appearance.colors.icon = UIColor($0) }
        )

        let dangerColorBinding = Binding(
            get: { Color(self.appearance.colors.danger) },
            set: { self.appearance.colors.danger = UIColor($0) }
        )

        let cornerRadiusBinding = Binding(
            get: { self.appearance.cornerRadius ?? -1 },
            set: { self.appearance.cornerRadius = $0 < 0 ? nil : $0 }
        )

        let sheetCornerRadiusBinding = Binding(
            get: { self.appearance.sheetCornerRadius },
            set: { self.appearance.sheetCornerRadius = $0 }
        )

        let borderWidthBinding = Binding(
            get: { self.appearance.borderWidth },
            set: { self.appearance.borderWidth = $0 }
        )

        let selectedBorderWidthBinding = Binding(
            get: { appearance.selectedBorderWidth ?? -0.5 },
            set: { self.appearance.selectedBorderWidth = $0 < 0 ? nil : $0 }
        )

        let componentShadowColorBinding = Binding(
            get: { Color(self.appearance.shadow.color) },
            set: { self.appearance.shadow.color = UIColor($0) }
        )

        let componentShadowAlphaBinding = Binding(
            get: { self.appearance.shadow.opacity },
            set: { self.appearance.shadow.opacity = $0 }
        )

        let componentShadowOffsetXBinding = Binding(
            get: { self.appearance.shadow.offset.width },
            set: { self.appearance.shadow.offset.width = $0 }
        )

        let componentShadowOffsetYBinding = Binding(
            get: { self.appearance.shadow.offset.height },
            set: { self.appearance.shadow.offset.height = $0 }
        )

        let componentShadowRadiusBinding = Binding(
            get: { self.appearance.shadow.radius },
            set: { self.appearance.shadow.radius = $0 }
        )

        let formInsetsTopBinding = Binding(
            get: { self.appearance.formInsets.top },
            set: { self.appearance.formInsets.top = $0 }
        )

        let formInsetsLeftBinding = Binding(
            get: { self.appearance.formInsets.leading },
            set: { self.appearance.formInsets.leading = $0 }
        )

        let formInsetsBottomBinding = Binding(
            get: { self.appearance.formInsets.bottom },
            set: { self.appearance.formInsets.bottom = $0 }
        )

        let formInsetsRightBinding = Binding(
            get: { self.appearance.formInsets.trailing },
            set: { self.appearance.formInsets.trailing = $0 }
        )

        let textFieldInsetsTopBinding = Binding(
            get: { self.appearance.textFieldInsets.top },
            set: { self.appearance.textFieldInsets.top = $0 }
        )

        let textFieldInsetsLeftBinding = Binding(
            get: { self.appearance.textFieldInsets.leading },
            set: { self.appearance.textFieldInsets.leading = $0 }
        )

        let textFieldInsetsBottomBinding = Binding(
            get: { self.appearance.textFieldInsets.bottom },
            set: { self.appearance.textFieldInsets.bottom = $0 }
        )

        let textFieldInsetsRightBinding = Binding(
            get: { self.appearance.textFieldInsets.trailing },
            set: { self.appearance.textFieldInsets.trailing = $0 }
        )

        let sizeScaleFactorBinding = Binding(
            get: { self.appearance.font.sizeScaleFactor },
            set: { self.appearance.font.sizeScaleFactor = $0 }
        )

        let regularFontBinding = Binding(
            get: { self.appearance.font.base == PaymentSheet.Appearance.default.font.base ? "System Default" : self.appearance.font.base.fontDescriptor.postscriptName },
            set: {
                if $0 == "System Default" {
                    self.appearance.font.base = PaymentSheet.Appearance.default.font.base
                } else {
                    self.appearance.font.base = UIFont(name: $0, size: 20.0)!
                }
            }
        )

        // MARK: Custom font bindings

        let customHeadlineFontBinding = Binding(
            get: { self.appearance.font.custom.headline?.fontDescriptor.postscriptName ?? "System Default" },
            set: {
                if $0 == "System Default" {
                    self.appearance.font.custom.headline = nil
                } else {
                    self.appearance.font.custom.headline = UIFont(name: $0, size: 20.0)!
                }
            }
        )

        // MARK: Primary button bindings

        let primaryButtonBackgroundColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.backgroundColor ?? self.appearance.colors.primary) },
            set: { self.appearance.primaryButton.backgroundColor = UIColor($0) }
        )

        let primaryButtonDisabledColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.disabledBackgroundColor ?? self.appearance.primaryButton.backgroundColor ?? self.appearance.colors.primary) },
            set: { self.appearance.primaryButton.disabledBackgroundColor = UIColor($0) }
        )

        let primaryButtonDisabledTextColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.disabledTextColor ?? self.appearance.primaryButton.textColor?.withAlphaComponent(0.6) ?? .white.withAlphaComponent(0.6)) },
            set: { self.appearance.primaryButton.disabledTextColor = UIColor($0) }
        )

        let primaryButtonSuccessColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.successBackgroundColor) },
            set: { self.appearance.primaryButton.successBackgroundColor = UIColor($0) }
        )

        let primaryButtonSuccessTextColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.successTextColor ?? self.appearance.primaryButton.textColor ?? .white) },
            set: { self.appearance.primaryButton.successTextColor = UIColor($0) }
        )

        let primaryButtonTextColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.textColor ?? UIColor.white) },
            set: { self.appearance.primaryButton.textColor = UIColor($0) }
        )

        let primaryButtonBorderColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.borderColor) },
            set: { self.appearance.primaryButton.borderColor = UIColor($0) }
        )

        let primaryButtonCornerRadiusBinding = Binding(
            get: { self.appearance.primaryButton.cornerRadius ?? appearance.cornerRadius ?? -1 },
            set: { self.appearance.primaryButton.cornerRadius = $0 }
        )

        let primaryButtonCornerBorderWidth = Binding(
            get: { self.appearance.primaryButton.borderWidth },
            set: { self.appearance.primaryButton.borderWidth = $0 }
        )

        let primaryButtonFontBinding = Binding(
            get: { self.appearance.primaryButton.font?.fontDescriptor.postscriptName ?? "System Default" },
            set: {
                self.appearance.primaryButton.font = $0 == "System Default" ? nil : UIFont(name: $0, size: 16.0)!
            }
        )

        let primaryButtonShadowColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.shadow?.color ?? PaymentSheet.Appearance.Shadow().color) },
            set: {
                if self.appearance.primaryButton.shadow == nil { self.appearance.primaryButton.shadow = PaymentSheet.Appearance.Shadow() }
                self.appearance.primaryButton.shadow?.color = UIColor($0)
            }
        )

        let primaryButtonShadowAlphaBinding = Binding(
            get: { self.appearance.primaryButton.shadow?.opacity ?? PaymentSheet.Appearance.Shadow().opacity },
            set: {
                if self.appearance.primaryButton.shadow == nil { self.appearance.primaryButton.shadow = PaymentSheet.Appearance.Shadow() }
                self.appearance.primaryButton.shadow?.opacity = $0
            }
        )

        let primaryButtonShadowOffsetXBinding = Binding(
            get: { self.appearance.primaryButton.shadow?.offset.width ?? PaymentSheet.Appearance.Shadow().offset.width },
            set: {
                if self.appearance.primaryButton.shadow == nil { self.appearance.primaryButton.shadow = PaymentSheet.Appearance.Shadow() }
                self.appearance.primaryButton.shadow?.offset.width = $0
            }
        )

        let primaryButtonShadowOffsetYBinding = Binding(
            get: { self.appearance.primaryButton.shadow?.offset.height ?? PaymentSheet.Appearance.Shadow().offset.height },
            set: {
                if self.appearance.primaryButton.shadow == nil { self.appearance.primaryButton.shadow = PaymentSheet.Appearance.Shadow() }
                self.appearance.primaryButton.shadow?.offset.height = $0
            }
        )

        let primaryButtonShadowRadiusBinding = Binding(
            get: { self.appearance.primaryButton.shadow?.radius ?? PaymentSheet.Appearance.Shadow().radius },
            set: {
                if self.appearance.primaryButton.shadow == nil { self.appearance.primaryButton.shadow = PaymentSheet.Appearance.Shadow() }
                self.appearance.primaryButton.shadow?.radius = $0
            }
        )

        let primaryButtonHeightBinding = Binding(
            get: { self.appearance.primaryButton.height },
            set: { self.appearance.primaryButton.height = $0 }
        )

        NavigationView {
            List {
                Section(header: Text("Colors")) {
                    Group {
                        ColorPicker("primary", selection: primaryColorBinding)
                        ColorPicker("background", selection: backgroundColorBinding)
                        ColorPicker("componentBackground", selection: componentBackgroundColorBinding)
                        ColorPicker("componentBorder", selection: componentBorderColorBinding)
                        ColorPicker("selectedComponentBorder", selection: selectedComponentBorderColorBinding)
                        ColorPicker("componentDivider", selection: componentDividerColorBinding)
                        ColorPicker("text", selection: textColorBinding)
                        ColorPicker("textSecondary", selection: textSecondaryColorBinding)
                        ColorPicker("componentText", selection: componentBackgroundTextColorBinding)
                        ColorPicker("componentPlaceholderText", selection: placeholderTextColorBinding)
                        ColorPicker("icon", selection: iconColorBinding)

                    }
                    // https://stackoverflow.com/questions/61178868/swiftui-random-extra-argument-in-call-error
                    ColorPicker("danger", selection: dangerColorBinding)
                }

                Section(header: Text("Miscellaneous")) {
                    let cornerRadiusLabel: String = {
                        if let cornerRadius = appearance.cornerRadius {
                            String(format: "cornerRadius: %.0f", cornerRadius)
                        } else {
                            "cornerRadius: nil"
                        }
                    }()
                    Stepper(cornerRadiusLabel, value: cornerRadiusBinding, in: -1...30)
                    Stepper(String(format: "sheetCornerRadius: %.0f", appearance.sheetCornerRadius), value: sheetCornerRadiusBinding, in: 0...30)
                    Stepper(String(format: "borderWidth: %.1f", appearance.borderWidth), value: borderWidthBinding, in: 0.0...2.0, step: 0.5)
                    let selectedBorderWidthLabel: String = {
                        if let selectedBorderWidth = appearance.selectedBorderWidth {
                            String(format: "selectedBorderWidth: %.0f", selectedBorderWidth)
                        } else {
                            "selectedBorderWidth: nil"
                        }
                    }()
                    Stepper(selectedBorderWidthLabel, value: selectedBorderWidthBinding, in: -0.5...2.0, step: 0.5)
                    Stepper(String(format: "sectionSpacing: %.1f", appearance.sectionSpacing), value: $appearance.sectionSpacing, in: 0...50, step: 1.0)
                    Stepper(String(format: "verticalModeRowPadding: %.1f", appearance.verticalModeRowPadding), value: $appearance.verticalModeRowPadding, in: 0...20, step: 0.5)
                    Picker("Icon Style", selection: $appearance.iconStyle) {
                        ForEach(PaymentSheet.Appearance.IconStyle.allCases, id: \.self) {
                            Text(String(describing: $0))
                        }
                    }
                    VStack {
                        Text("componentShadow")
                        ColorPicker("color", selection: componentShadowColorBinding)

                        HStack {
                            Text(String(format: "alpha: %.2f", appearance.shadow.opacity))
                            Slider(value: componentShadowAlphaBinding, in: 0...1, step: 0.05)
                        }

                        Stepper("offset.x: \(Int(appearance.shadow.offset.width))",
                                value: componentShadowOffsetXBinding, in: 0...20)
                        Stepper("offset.y: \(Int(appearance.shadow.offset.height))",
                                value: componentShadowOffsetYBinding, in: 0...20)

                        HStack {
                            Text(String(format: "radius: %.1f", appearance.shadow.radius))
                            Slider(value: componentShadowRadiusBinding, in: 0...10, step: 0.5)
                        }
                    }
                    VStack {
                        Text("formInsets")
                        Stepper("top: \(Int(appearance.formInsets.top))",
                                value: formInsetsTopBinding, in: 0...100)
                        Stepper("left: \(Int(appearance.formInsets.leading))",
                                value: formInsetsLeftBinding, in: 0...100)
                        Stepper("bottom: \(Int(appearance.formInsets.bottom))",
                                value: formInsetsBottomBinding, in: 0...100)
                        Stepper("right: \(Int(appearance.formInsets.trailing))",
                                value: formInsetsRightBinding, in: 0...100)
                    }
                    VStack {
                        Text("textFieldInsets")
                        Stepper("top: \(Int(appearance.textFieldInsets.top))",
                                value: textFieldInsetsTopBinding, in: 0...50)
                        Stepper("left: \(Int(appearance.textFieldInsets.leading))",
                                value: textFieldInsetsLeftBinding, in: 0...50)
                        Stepper("bottom: \(Int(appearance.textFieldInsets.bottom))",
                                value: textFieldInsetsBottomBinding, in: 0...50)
                        Stepper("right: \(Int(appearance.textFieldInsets.trailing))",
                                value: textFieldInsetsRightBinding, in: 0...50)
                    }
                }
                Section(header: Text("Fonts")) {
                    VStack {
                        Text(String(format: "sizeScaleFactor: %.2f", appearance.font.sizeScaleFactor))
                        Slider(value: sizeScaleFactorBinding, in: 0...2, step: 0.05)
                    }
                    Picker("Regular", selection: regularFontBinding) {
                        ForEach(Self.fonts, id: \.self) {
                            if $0 == "System Default" {
                                Text($0)
                            } else {
                                Text($0).font(Font(UIFont(name: $0, size: UIFont.labelFontSize)! as CTFont))
                            }
                        }
                    }

                    DisclosureGroup {
                        Picker("headline", selection: customHeadlineFontBinding) {
                            ForEach(Self.fonts, id: \.self) { font in
                                if font == "System Default" {
                                    Text(font)
                                } else {
                                    Text(font).font(Font(UIFont(name: font, size: UIFont.labelFontSize)! as CTFont))
                                }
                            }
                        }
                    } label: {
                        Text("Custom Fonts")
                    }
                }

                Section(header: Text("Primary Button")) {
                    DisclosureGroup {
                        ColorPicker("backgroundColor", selection: primaryButtonBackgroundColorBinding)
                        ColorPicker("disabledBackgroundColor", selection: primaryButtonDisabledColorBinding)
                        ColorPicker("disabledTextColor", selection: primaryButtonDisabledTextColorBinding)
                        ColorPicker("successBackgroundColor", selection: primaryButtonSuccessColorBinding)
                        ColorPicker("successTextColor", selection: primaryButtonSuccessTextColorBinding)
                        ColorPicker("textColor", selection: primaryButtonTextColorBinding)
                        ColorPicker("borderColor", selection: primaryButtonBorderColorBinding)
                        Stepper("borderWidth: \(Int(appearance.primaryButton.borderWidth))", value: primaryButtonCornerBorderWidth, in: 0...30)
                        let cornerRadiusLabel: String = {
                            if let cornerRadius = appearance.primaryButton.cornerRadius {
                                String(format: "cornerRadius: %.1f", cornerRadius)
                            } else {
                                "cornerRadius: nil"
                            }
                        }()
                        Stepper(cornerRadiusLabel, value: primaryButtonCornerRadiusBinding, in: -1...30)
                        Picker("Font", selection: primaryButtonFontBinding) {
                            ForEach(Self.fonts, id: \.self) { font in
                                if font == "System Default" {
                                    Text(font)
                                } else {
                                    Text(font).font(Font(UIFont(name: font, size: UIFont.labelFontSize)! as CTFont))
                                }
                            }
                        }
                        VStack {
                            Text("shadow")
                            ColorPicker("color", selection: primaryButtonShadowColorBinding)

                            HStack {
                                Text(String(format: "alpha: %.2f", appearance.primaryButton.shadow?.opacity ?? PaymentSheet.Appearance.Shadow().opacity))
                                Slider(value: primaryButtonShadowAlphaBinding, in: 0...1, step: 0.05)
                            }

                            Stepper("offset.x: \(Int(appearance.primaryButton.shadow?.offset.width ?? PaymentSheet.Appearance.Shadow().offset.width))",
                                    value: primaryButtonShadowOffsetXBinding, in: 0...20)
                            Stepper("offset.y: \(Int(appearance.primaryButton.shadow?.offset.height ?? PaymentSheet.Appearance.Shadow().offset.height))",
                                    value: primaryButtonShadowOffsetYBinding, in: 0...20)

                            HStack {
                                Text(String(format: "radius: %.1f", appearance.primaryButton.shadow?.radius ?? PaymentSheet.Appearance.Shadow().radius))
                                Slider(value: primaryButtonShadowRadiusBinding, in: 0...10, step: 0.5)
                            }
                        }
                        HStack {
                            Text(String(format: "height: \(appearance.primaryButton.height)"))
                            Slider(value: primaryButtonHeightBinding, in: 20...100, step: 1)
                        }
                    } label: {
                        Text("Primary Button")
                    }
                }

                Section(header: Text("EmbeddedPaymentElement")) {
                    AppearancePlaygroundView_EmbeddedPaymentElement(appearance: $appearance)
                }

                if #available(iOS 26.0, *) {
                    Section(header: Text("iOS 26 Liquid Glass")) {
                        Picker("Navigation bar style", selection: $appearance.navigationBarStyle) {
                            ForEach([PaymentSheet.Appearance.NavigationBarStyle.plain, PaymentSheet.Appearance.NavigationBarStyle.glass], id: \.self) {
                                Text(String(describing: $0))
                            }
                        }
                        Button {
                            appearance.applyLiquidGlass()
                            doneAction(appearance)
                        } label: {
                            Text("Apply Liquid Glass🥃")
                        }
                        Button {
                            appearance = PaymentSheet.Appearance()
                            appearance.applyLiquidGlass()
                            doneAction(appearance)
                        } label: {
                            Text("♼ Reset Appearance, apply Liquid Glass 🥃")
                        }
                    }
                }
                Button {
                    LiquidGlassDetector.allowNewDesign = false
                    appearance = PaymentSheet.Appearance()
                    doneAction(appearance)
                } label: {
                    Text("♼ Reset Appearance")
                }

            }.navigationTitle("Appearance")
             .toolbar {
                    Button("Done") {
                        doneAction(appearance)
                    }
            }
        }
    }
}

struct AppearancePlaygroundView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            AppearancePlaygroundView(appearance: PaymentSheet.Appearance(), doneAction: { _ in })
        }
    }
}
