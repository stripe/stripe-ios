//
//  AppearancePlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/1/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import SwiftUI
@_spi(STP) import Stripe

@available(iOS 14.0, *)
struct AppearancePlaygroundView: View {
    @State var appearance: PaymentSheet.Appearance
    var doneAction: ((PaymentSheet.Appearance) -> Void) = {_ in }
    
    init(appearance: PaymentSheet.Appearance, doneAction: @escaping ((PaymentSheet.Appearance) -> Void)) {
        _appearance = State<PaymentSheet.Appearance>.init(initialValue: appearance)
        self.doneAction = doneAction
    }
    
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
            get: { self.appearance.cornerRadius },
            set: { self.appearance.cornerRadius = $0 }
        )
        
        let componentBorderWidthBinding = Binding(
            get: { self.appearance.borderWidth },
            set: { self.appearance.borderWidth = $0 }
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
        
        let sizeScaleFactorBinding = Binding(
            get: { self.appearance.font.sizeScaleFactor },
            set: { self.appearance.font.sizeScaleFactor = $0 }
        )
        
        let regularFontBinding = Binding(
            get: { self.appearance.font.base.fontDescriptor.postscriptName },
            set: { self.appearance.font.base = UIFont(name: $0, size: 12.0)! }
        )
        
        // MARK: Primary button bindings
        
        let primaryButtonBackgroundColorBinding = Binding(
            get: { Color(self.appearance.primaryButton.backgroundColor ?? self.appearance.colors.primary) },
            set: { self.appearance.primaryButton.backgroundColor = UIColor($0) }
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
            get: { self.appearance.primaryButton.cornerRadius ?? appearance.cornerRadius },
            set: { self.appearance.primaryButton.cornerRadius = $0 }
        )
        
        let primaryButtonCornerBorderWidth = Binding(
            get: { self.appearance.primaryButton.borderWidth},
            set: { self.appearance.primaryButton.borderWidth = $0 }
        )
        
        let primaryButtonFontBinding = Binding(
            get: { self.appearance.primaryButton.font?.fontDescriptor.postscriptName ?? UIFont.systemFont(ofSize: 16, weight: .medium).fontDescriptor.postscriptName },
            set: { self.appearance.primaryButton.font = UIFont(name: $0, size: 16.0)! }
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
        
        
        let regularFonts = ["AvenirNext-Regular", "PingFangHK-Regular", "ChalkboardSE-Light"]
        
        NavigationView {
            List {
                Section(header: Text("Colors")) {
                    Group {
                        ColorPicker("primary", selection: primaryColorBinding)
                        ColorPicker("background", selection: backgroundColorBinding)
                        ColorPicker("componentBackground", selection: componentBackgroundColorBinding)
                        ColorPicker("componentBorder", selection: componentBorderColorBinding)
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
                    Stepper("cornerRadius: \(Int(appearance.cornerRadius))", value: cornerRadiusBinding, in: 0...30)
                    Stepper("componentBorderWidth: \(Int(appearance.borderWidth))", value: componentBorderWidthBinding, in: 0...30)
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
                }
                Section(header: Text("Fonts")) {
                    VStack {
                        Text(String(format: "sizeScaleFactor: %.2f", appearance.font.sizeScaleFactor))
                        Slider(value: sizeScaleFactorBinding, in: 0...2, step: 0.05)
                    }
                    Picker("Regular", selection: regularFontBinding) {
                        ForEach(regularFonts, id: \.self) {
                            Text($0).font(Font(UIFont(name: $0, size: UIFont.labelFontSize)! as CTFont))
                        }
                    }
                }
                
                Section(header: Text("Primary Button")) {
                    DisclosureGroup {
                        ColorPicker("backgroundColor", selection: primaryButtonBackgroundColorBinding)
                        ColorPicker("textColor", selection: primaryButtonTextColorBinding)
                        ColorPicker("borderColor", selection: primaryButtonBorderColorBinding)
                        Stepper("borderWidth: \(Int(appearance.primaryButton.borderWidth))", value: primaryButtonCornerBorderWidth, in: 0...30)
                        Stepper("cornerRadius: \(Int(appearance.primaryButton.cornerRadius ?? appearance.cornerRadius))",
                                value: primaryButtonCornerRadiusBinding, in: 0...30)
                        Picker("Font", selection: primaryButtonFontBinding) {
                            ForEach(regularFonts, id: \.self) {
                                Text($0).font(Font(UIFont(name: $0, size: UIFont.labelFontSize)! as CTFont))
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
                    } label: {
                        Text("Primary Button")
                    }
                }
                
                Button {
                    appearance = PaymentSheet.Appearance()
                    doneAction(appearance)
                } label: {
                    Text("Reset Appearance")
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
            AppearancePlaygroundView(appearance: PaymentSheet.Appearance(), doneAction: {_ in })
        }
    }
}
