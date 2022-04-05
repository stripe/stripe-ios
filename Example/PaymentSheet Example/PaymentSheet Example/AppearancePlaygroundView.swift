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
            get: { Color(self.appearance.color.primary) },
            set: { self.appearance.color.primary = UIColor($0) }
        )
    
        let backgroundColorBinding = Binding(
            get: { Color(self.appearance.color.background) },
            set: { self.appearance.color.background = UIColor($0) }
        )
        
        let componentBackgroundColorBinding = Binding(
            get: { Color(self.appearance.color.componentBackground) },
            set: { self.appearance.color.componentBackground = UIColor($0) }
        )
        
        let componentBorderColorBinding = Binding(
            get: { Color(self.appearance.color.componentBorder) },
            set: { self.appearance.color.componentBorder = UIColor($0) }
        )
        
        let componentDividerColorBinding = Binding(
            get: { Color(self.appearance.color.componentDivider) },
            set: { self.appearance.color.componentDivider = UIColor($0) }
        )
        
        let textColorBinding = Binding(
            get: { Color(self.appearance.color.text) },
            set: { self.appearance.color.text = UIColor($0) }
        )
        
        let textSecondaryColorBinding = Binding(
            get: { Color(self.appearance.color.textSecondary) },
            set: { self.appearance.color.textSecondary = UIColor($0) }
        )
        
        let componentBackgroundTextColorBinding = Binding(
            get: { Color(self.appearance.color.componentBackgroundText) },
            set: { self.appearance.color.componentBackgroundText = UIColor($0) }
        )
        
        let placeholderTextColorBinding = Binding(
            get: { Color(self.appearance.color.placeholderText) },
            set: { self.appearance.color.placeholderText = UIColor($0) }
        )
        
        let iconColorBinding = Binding(
            get: { Color(self.appearance.color.icon) },
            set: { self.appearance.color.icon = UIColor($0) }
        )
        
        let dangerColorBinding = Binding(
            get: { Color(self.appearance.color.danger) },
            set: { self.appearance.color.danger = UIColor($0) }
        )
        
        let cornerRadiusBinding = Binding(
            get: { self.appearance.shape.cornerRadius },
            set: { self.appearance.shape.cornerRadius = $0 }
        )
        
        let componentBorderWidthBinding = Binding(
            get: { self.appearance.shape.componentBorderWidth },
            set: { self.appearance.shape.componentBorderWidth = $0 }
        )
        
        let componentShadowColorBinding = Binding(
            get: { Color(self.appearance.shape.componentShadow.color) },
            set: { self.appearance.shape.componentShadow.color = UIColor($0) }
        )
        
        let componentShadowAlphaBinding = Binding(
            get: { self.appearance.shape.componentShadow.alpha },
            set: { self.appearance.shape.componentShadow.alpha = $0 }
        )
        
        let componentShadowOffsetXBinding = Binding(
            get: { self.appearance.shape.componentShadow.offset.width },
            set: { self.appearance.shape.componentShadow.offset.width = $0 }
        )
        
        let componentShadowOffsetYBinding = Binding(
            get: { self.appearance.shape.componentShadow.offset.height },
            set: { self.appearance.shape.componentShadow.offset.height = $0 }
        )
        
        let componentShadowRadiusBinding = Binding(
            get: { self.appearance.shape.componentShadow.radius },
            set: { self.appearance.shape.componentShadow.radius = $0 }
        )
        
        let sizeScaleFactorBinding = Binding(
            get: { self.appearance.font.sizeScaleFactor },
            set: { self.appearance.font.sizeScaleFactor = $0 }
        )
        
        let regularFontBinding = Binding(
            get: { self.appearance.font.regular.fontDescriptor.postscriptName },
            set: { self.appearance.font.regular = UIFont(name: $0, size: 12.0)! }
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
                        ColorPicker("componentBackgroundText", selection: componentBackgroundTextColorBinding)
                        ColorPicker("placeholderText", selection: placeholderTextColorBinding)
                        ColorPicker("icon", selection: iconColorBinding)
                        
                    }
                    // https://stackoverflow.com/questions/61178868/swiftui-random-extra-argument-in-call-error
                    ColorPicker("danger", selection: dangerColorBinding)
                }
                
                Section(header: Text("Shape")) {
                    Stepper("cornerRadius: \(Int(appearance.shape.cornerRadius))", value: cornerRadiusBinding, in: 0...30)
                    Stepper("componentBorderWidth: \(Int(appearance.shape.componentBorderWidth))", value: componentBorderWidthBinding, in: 0...30)
                    VStack {
                        Text("componentShadow")
                        ColorPicker("color", selection: componentShadowColorBinding)
                        
                        HStack {
                            Text(String(format: "alpha: %.2f", appearance.shape.componentShadow.alpha))
                            Slider(value: componentShadowAlphaBinding, in: 0...1, step: 0.05)
                        }

                        Stepper("offset.x: \(Int(appearance.shape.componentShadow.offset.width))",
                                value: componentShadowOffsetXBinding, in: 0...20)
                        Stepper("offset.y: \(Int(appearance.shape.componentShadow.offset.height))",
                                value: componentShadowOffsetYBinding, in: 0...20)
                        
                        HStack {
                            Text(String(format: "radius: %.1f", appearance.shape.componentShadow.radius))
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
                
                Button {
                    appearance = PaymentSheet.Appearance.snapshotTestTheme
                    doneAction(appearance)
                } label: {
                    Text("Snapshot testing Appearance")
                }.accessibilityIdentifier("testing_appearance")

                
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

extension PaymentSheet.Appearance {
    static var snapshotTestTheme: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()

        // Customize the font
        var font = PaymentSheet.Appearance.Font()
        font.sizeScaleFactor = 0.85
        font.regular = UIFont(name: "AvenirNext-Regular", size: 12)!
        

        // Customize the shapes
        var shape = PaymentSheet.Appearance.Shape()
        shape.cornerRadius = 0.0
        shape.componentBorderWidth = 2.0
        shape.componentShadow = PaymentSheet.Appearance.Shape.Shadow(color: .orange,
                                                          alpha: 0.5,
                                                          offset: CGSize(width: 0, height: 2),
                                                                     radius: 4)

        // Customize the colors
        var colors = PaymentSheet.Appearance.Color()
        colors.primary = .systemOrange
        colors.background = .cyan
        colors.componentBackground = .yellow
        colors.componentBorder = .systemRed
        colors.componentDivider = .black
        colors.text = .red
        colors.textSecondary = .orange
        colors.componentBackgroundText = .red
        colors.placeholderText = .systemBlue
        colors.icon = .green
        colors.danger = .purple

        appearance.font = font
        appearance.shape = shape
        appearance.color = colors
        
        return appearance
    }
}
