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
                
                Section(header: Text("Shape (TODO)")) {
                    Text("cornerRadius")
                    Text("componentBorderWidth")
                    Text("componentShadow")
                }
                Section(header: Text("Fonts (TODO)")) {
                    Text("sizeBase")
                    Text("weightRegular")
                    Text("weightMedium")
                    Text("weightSemiBold")
                    Text("weightBold")
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
