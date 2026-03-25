//
//  AppearancePlaygroundView+EmbeddedPaymentElement.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 7/17/25.
//

@_spi(AppearanceAPIAdditionsPreview) import StripePaymentSheet
import SwiftUI

@available(iOS 14.0, *)
struct AppearancePlaygroundView_EmbeddedPaymentElement: View {
    @Binding var appearance: PaymentSheet.Appearance

    enum TitleFont: String, CaseIterable, Identifiable {
        case none, nonbold
        var id: Self { self }
    }

    var body: some View {
        let embeddedPaymentElementFlatSeparatorColorBinding = Binding(
            get: { Color(self.appearance.embeddedPaymentElement.row.flat.separatorColor ?? appearance.colors.componentBorder) },
            set: {
                if self.appearance.embeddedPaymentElement.row.flat.separatorColor == nil {
                    self.appearance.embeddedPaymentElement.row.flat.separatorColor = appearance.colors.componentBorder
                } else {
                    self.appearance.embeddedPaymentElement.row.flat.separatorColor = UIColor($0)
                }
            }
        )

        let embeddedPaymentElementFlatRadioColorSelected = Binding(
            get: { Color(self.appearance.embeddedPaymentElement.row.flat.radio.selectedColor ?? appearance.colors.primary) },
            set: {
                self.appearance.embeddedPaymentElement.row.flat.radio.selectedColor = UIColor($0)
            }
        )

        let embeddedPaymentElementFlatRadioColorUnselected = Binding(
            get: { Color(self.appearance.embeddedPaymentElement.row.flat.radio.unselectedColor ?? appearance.colors.componentBorder) },
            set: {
                self.appearance.embeddedPaymentElement.row.flat.radio.unselectedColor = UIColor($0)
            }
        )

        let embeddedPaymentElementFlatLeftSeparatorInset = Binding(
            get: { self.appearance.embeddedPaymentElement.row.flat.separatorInsets?.left ?? 0 },
            set: {
                let prevInsets = self.appearance.embeddedPaymentElement.row.flat.separatorInsets ?? .zero
                self.appearance.embeddedPaymentElement.row.flat.separatorInsets = UIEdgeInsets(top: 0, left: $0, bottom: 0, right: prevInsets.right)
            }
        )

        let embeddedPaymentElementFlatRightSeparatorInset = Binding(
            get: { self.appearance.embeddedPaymentElement.row.flat.separatorInsets?.right ?? 0 },
            set: {
                let prevInsets = self.appearance.embeddedPaymentElement.row.flat.separatorInsets ?? .zero
                self.appearance.embeddedPaymentElement.row.flat.separatorInsets = UIEdgeInsets(top: 0, left: prevInsets.left, bottom: 0, right: $0)
            }
        )

        let embeddedPaymentElementCheckmarkColorBinding = Binding(
            get: { Color(self.appearance.embeddedPaymentElement.row.flat.checkmark.color ?? self.appearance.colors.primary) },
            set: { self.appearance.embeddedPaymentElement.row.flat.checkmark.color = UIColor($0) }
        )

        let embeddedPaymentElementDisclosureColorBinding = Binding(
            get: { Color(self.appearance.embeddedPaymentElement.row.flat.disclosure.color) },
            set: { self.appearance.embeddedPaymentElement.row.flat.disclosure.color = UIColor($0) }
        )
        let paymentMethodIconLayoutMarginsLeading = Binding(
            get: { self.appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins.leading },
            set: { self.appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins.leading = $0 }
        )
        let paymentMethodIconLayoutMarginsTrailing = Binding(
            get: { self.appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins.trailing },
            set: { self.appearance.embeddedPaymentElement.row.paymentMethodIconLayoutMargins.trailing = $0 }
        )
        let selectedTitleFont = Binding<TitleFont>(
            get: {
                switch self.appearance.embeddedPaymentElement.row.titleFont {
                case .some:
                    return TitleFont.nonbold
                case .none:
                    return TitleFont.none
                }
            },
            set: {
                let font: UIFont?
                switch $0 {
                case .none:
                    font = nil
                case .nonbold:
                    font = .systemFont(ofSize: 14, weight: .regular)
                }
                self.appearance.embeddedPaymentElement.row.titleFont = font
            }
        )

        DisclosureGroup("EmbeddedPaymentElement.Row") {
            Picker("Style", selection: $appearance.embeddedPaymentElement.row.style) {
                ForEach(PaymentSheet.Appearance.EmbeddedPaymentElement.Row.Style.allCases, id: \.self) {
                    Text(String(describing: $0))
                }
            }

            Stepper("additionalInsets: \(Int(appearance.embeddedPaymentElement.row.additionalInsets))",
                    value: $appearance.embeddedPaymentElement.row.additionalInsets, in: 0...40)
            VStack {
                Text("paymentMethodIconLayoutMargins")
                Stepper("leading: \(Int(paymentMethodIconLayoutMarginsLeading.wrappedValue))",
                        value: paymentMethodIconLayoutMarginsLeading, in: 0...50)
                Stepper("trailing: \(Int(paymentMethodIconLayoutMarginsTrailing.wrappedValue))",
                        value: paymentMethodIconLayoutMarginsTrailing, in: 0...50)
            }

            Picker("titleFont", selection: selectedTitleFont) {
                ForEach(TitleFont.allCases) {
                    Text($0.rawValue.capitalized).tag($0)
                }
            }
            DisclosureGroup {
                Stepper("separatorThickness: \(Int(appearance.embeddedPaymentElement.row.flat.separatorThickness))",
                        value: $appearance.embeddedPaymentElement.row.flat.separatorThickness, in: 0...10)
                ColorPicker("separatorColor", selection: embeddedPaymentElementFlatSeparatorColorBinding)
                Stepper("leftSeparatorInset: \(Int(appearance.embeddedPaymentElement.row.flat.separatorInsets?.left ?? 0))",
                        value: embeddedPaymentElementFlatLeftSeparatorInset, in: -40...40)
                Stepper("rightSeparatorInset: \(Int(appearance.embeddedPaymentElement.row.flat.separatorInsets?.right ?? 0))",
                        value: embeddedPaymentElementFlatRightSeparatorInset, in: -40...40)
                Toggle("topSeparatorEnabled", isOn: $appearance.embeddedPaymentElement.row.flat.topSeparatorEnabled)
                Toggle("bottomSeparatorEnabled", isOn: $appearance.embeddedPaymentElement.row.flat.bottomSeparatorEnabled)

                DisclosureGroup {
                    ColorPicker("selectedColor", selection: embeddedPaymentElementFlatRadioColorSelected)
                    ColorPicker("unselectedColor", selection: embeddedPaymentElementFlatRadioColorUnselected)
                } label: {
                    Text("Radio")
                }
                DisclosureGroup {
                    ColorPicker("checkmarkColor", selection: embeddedPaymentElementCheckmarkColorBinding)
                } label: {
                    Text("Checkmark")
                }
                DisclosureGroup {
                    ColorPicker("chevronColor", selection: embeddedPaymentElementDisclosureColorBinding)
                } label: {
                    Text("Chevron")
                }
            } label: {
                Text("Flat")
            }

            DisclosureGroup {
                Stepper("Spacing: \(Int(appearance.embeddedPaymentElement.row.floating.spacing))",
                        value: $appearance.embeddedPaymentElement.row.floating.spacing, in: 0...40)

            } label: {
                Text("FloatingButton")
            }
        }
    }
}
