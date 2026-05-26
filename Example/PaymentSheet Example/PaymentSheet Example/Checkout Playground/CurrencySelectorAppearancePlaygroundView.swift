//
//  CurrencySelectorAppearancePlaygroundView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 5/18/26.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
struct CurrencySelectorAppearancePlaygroundView: View {
    @State var appearance: Checkout.CurrencySelectorView.Appearance
    var doneAction: ((Checkout.CurrencySelectorView.Appearance) -> Void)

    static let fonts = ["System Default", "AvenirNext-Regular", "PingFangHK-Regular", "ChalkboardSE-Light"]

    var body: some View {
        NavigationView {
            List {
                dimensionsSection
                colorsSection
                typographySection
                contentSection
                resetSection
            }
            .navigationTitle("Currency Selector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        doneAction(appearance)
                    }
                }
            }
        }
    }

    // MARK: - Dimensions

    @ViewBuilder
    private var dimensionsSection: some View {
        Section("Dimensions") {
            VStack(alignment: .leading) {
                Text("Height: \(appearance.height, specifier: "%.0f")")
                Slider(value: $appearance.height, in: 24...60, step: 1)
            }
            VStack(alignment: .leading) {
                Text("Corner Radius: \(appearance.cornerRadius, specifier: "%.0f")")
                Slider(value: $appearance.cornerRadius, in: 0...30, step: 1)
            }
            VStack(alignment: .leading) {
                Text("Border Width: \(appearance.borderWidth, specifier: "%.1f")")
                Slider(value: $appearance.borderWidth, in: 0...4, step: 0.5)
            }
        }
    }

    // MARK: - Colors

    @ViewBuilder
    private var colorsSection: some View {
        let borderBinding = Binding(
            get: { Color(appearance.border) },
            set: { appearance.border = UIColor($0) }
        )
        let backgroundBinding = Binding(
            get: { Color(appearance.background) },
            set: { appearance.background = UIColor($0) }
        )
        let selectedBackgroundBinding = Binding(
            get: { Color(appearance.selectedBackground) },
            set: { appearance.selectedBackground = UIColor($0) }
        )
        let textBinding = Binding(
            get: { Color(appearance.text) },
            set: { appearance.text = UIColor($0) }
        )
        let selectedTextBinding = Binding(
            get: { Color(appearance.selectedText) },
            set: { appearance.selectedText = UIColor($0) }
        )
        let textSecondaryBinding = Binding(
            get: { Color(appearance.textSecondary) },
            set: { appearance.textSecondary = UIColor($0) }
        )
        let dangerBinding = Binding(
            get: { Color(appearance.danger) },
            set: { appearance.danger = UIColor($0) }
        )

        Section("Colors") {
            ColorPicker("Border", selection: borderBinding)
            ColorPicker("Background", selection: backgroundBinding)
            ColorPicker("Selected Background", selection: selectedBackgroundBinding)
            ColorPicker("Text", selection: textBinding)
            ColorPicker("Selected Text", selection: selectedTextBinding)
            ColorPicker("Text Secondary", selection: textSecondaryBinding)
            ColorPicker("Danger", selection: dangerBinding)
        }
    }

    // MARK: - Typography

    @ViewBuilder
    private var typographySection: some View {
        Section("Typography") {
            VStack(alignment: .leading) {
                Text("Size Scale Factor: \(appearance.sizeScaleFactor, specifier: "%.2f")")
                Slider(value: $appearance.sizeScaleFactor, in: 0.5...2.0, step: 0.05)
            }
            Picker("Font", selection: Binding(
                get: { fontName(from: appearance.font) },
                set: { newValue in
                    if newValue == "System Default" {
                        appearance.font = .systemFont(ofSize: 14, weight: .medium)
                    } else {
                        appearance.font = UIFont(name: newValue, size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
                    }
                }
            )) {
                ForEach(Self.fonts, id: \.self) { font in
                    Text(font).tag(font)
                }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        Section("Content") {
            Picker("Label Content", selection: $appearance.labelContent) {
                Text("Currency Code").tag(Checkout.CurrencySelectorView.Appearance.LabelContent.currencyCode)
                Text("Amount").tag(Checkout.CurrencySelectorView.Appearance.LabelContent.amount)
            }
        }
    }

    // MARK: - Reset

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button("Reset to Defaults") {
                withAnimation {
                    appearance = Checkout.CurrencySelectorView.Appearance()
                }
            }
            .foregroundColor(.red)
        }
    }

    private func fontName(from font: UIFont) -> String {
        if font.fontName.hasPrefix(".SFUI") || font.fontName.hasPrefix(".AppleSystemUI") {
            return "System Default"
        }
        return font.fontName
    }
}
