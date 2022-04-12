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
        
        // TODO(porter) Don't force unwrap shadow
        let componentShadowColorBinding = Binding(
            get: { Color(self.appearance.shadow!.color) },
            set: { self.appearance.shadow!.color = UIColor($0) }
        )
        
        let componentShadowAlphaBinding = Binding(
            get: { self.appearance.shadow!.opacity },
            set: { self.appearance.shadow!.opacity = $0 }
        )
        
        let componentShadowOffsetXBinding = Binding(
            get: { self.appearance.shadow!.offset.width },
            set: { self.appearance.shadow!.offset.width = $0 }
        )
        
        let componentShadowOffsetYBinding = Binding(
            get: { self.appearance.shadow!.offset.height },
            set: { self.appearance.shadow!.offset.height = $0 }
        )
        
        let componentShadowRadiusBinding = Binding(
            get: { self.appearance.shadow!.radius },
            set: { self.appearance.shadow!.radius = $0 }
        )
        
        let sizeScaleFactorBinding = Binding(
            get: { self.appearance.font.sizeScaleFactor },
            set: { self.appearance.font.sizeScaleFactor = $0 }
        )
        
        let regularFontBinding = Binding(
            get: { self.appearance.font.base.fontDescriptor.postscriptName },
            set: { self.appearance.font.base = UIFont(name: $0, size: 12.0)! }
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
                            Text(String(format: "alpha: %.2f", appearance.shadow!.opacity))
                            Slider(value: componentShadowAlphaBinding, in: 0...1, step: 0.05)
                        }

                        Stepper("offset.x: \(Int(appearance.shadow!.offset.width))",
                                value: componentShadowOffsetXBinding, in: 0...20)
                        Stepper("offset.y: \(Int(appearance.shadow!.offset.height))",
                                value: componentShadowOffsetYBinding, in: 0...20)
                        
                        HStack {
                            Text(String(format: "radius: %.1f", appearance.shadow!.radius))
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
