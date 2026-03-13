//
//  CustomThemeSettingsView.swift
//  StripeConnect Example
//

import StripeConnect
import SwiftUI

struct CustomThemeSettingsView: View {
    let componentManager: EmbeddedComponentManager?

    private static let textTransformPlaceholder = "none, uppercase, lowercase, capitalize"
    private static let fontWeightPlaceholder = "100-900 (e.g. 400, 600)"
    private static let colorPlaceholder = "6-digit hex (e.g. 0969DA)"

    private func updateComponentManager() {
        componentManager?.update(appearance: AppSettings.shared.appearanceInfo.appearance)
    }

    /// Binding to a custom theme field in UserDefaults; updates preview when value changes.
    private func customThemeBinding(_ keyPath: WritableKeyPath<AppSettings, String>) -> Binding<String> {
        let settings = AppSettings.shared
        return Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                settings[keyPath: keyPath] = newValue
                self.updateComponentManager()
            }
        )
    }

    /// Helper view that wraps TextInput and updates the theme instantly
    private func UpdateTextInput(label: String, placeholder: String, text: Binding<String>) -> some View {
        TextInput(label: label, placeholder: placeholder, text: text)
            .onChange(of: text.wrappedValue) { _ in
                updateComponentManager()
            }
    }

    var body: some View {
        List {
            Section {
                UpdateTextInput(label: "formPlaceholderTextColor", placeholder: Self.colorPlaceholder, text: customThemeBinding(\.formPlaceholderTextColor))
                UpdateTextInput(label: "inputFieldPaddingX", placeholder: "16", text: customThemeBinding(\.inputFieldPaddingX))
                UpdateTextInput(label: "inputFieldPaddingY", placeholder: "12", text: customThemeBinding(\.inputFieldPaddingY))
            } header: { Text("Form") }

            Section {
                UpdateTextInput(label: "actionPrimaryTextTransform", placeholder: Self.textTransformPlaceholder, text: customThemeBinding(\.actionPrimaryTextTransform))
                UpdateTextInput(label: "actionSecondaryTextTransform", placeholder: Self.textTransformPlaceholder, text: customThemeBinding(\.actionSecondaryTextTransform))
            } header: { Text("Action") }

            Section {
                UpdateTextInput(label: "tableRowPaddingY", placeholder: "8", text: customThemeBinding(\.tableRowPaddingY))
            } header: { Text("Table") }

            Section {
                UpdateTextInput(label: "buttonDangerColorBackground", placeholder: Self.colorPlaceholder, text: customThemeBinding(\.buttonDangerColorBackground))
                UpdateTextInput(label: "buttonDangerColorBorder", placeholder: Self.colorPlaceholder, text: customThemeBinding(\.buttonDangerColorBorder))
                UpdateTextInput(label: "buttonDangerColorText", placeholder: Self.colorPlaceholder, text: customThemeBinding(\.buttonDangerColorText))
            } header: { Text("Button danger") }

            Section {
                UpdateTextInput(label: "badgeLabelTextTransform", placeholder: Self.textTransformPlaceholder, text: customThemeBinding(\.badgeLabelTextTransform))
                UpdateTextInput(label: "badgeLabelFontWeight", placeholder: Self.fontWeightPlaceholder, text: customThemeBinding(\.badgeLabelFontWeight))
                UpdateTextInput(label: "badgeLabelFontSize", placeholder: "14", text: customThemeBinding(\.badgeLabelFontSize))
                UpdateTextInput(label: "badgePaddingY", placeholder: "2", text: customThemeBinding(\.badgePaddingY))
                UpdateTextInput(label: "badgePaddingX", placeholder: "6", text: customThemeBinding(\.badgePaddingX))
            } header: { Text("Badge label") }

            Section {
                UpdateTextInput(label: "buttonLabelTextTransform", placeholder: Self.textTransformPlaceholder, text: customThemeBinding(\.buttonLabelTextTransform))
                UpdateTextInput(label: "buttonLabelFontWeight", placeholder: Self.fontWeightPlaceholder, text: customThemeBinding(\.buttonLabelFontWeight))
                UpdateTextInput(label: "buttonLabelFontSize", placeholder: "16", text: customThemeBinding(\.buttonLabelFontSize))
                UpdateTextInput(label: "buttonPaddingY", placeholder: "4", text: customThemeBinding(\.buttonPaddingY))
                UpdateTextInput(label: "buttonPaddingX", placeholder: "8", text: customThemeBinding(\.buttonPaddingX))
            } header: { Text("Button label") }

            Section {
                UpdateTextInput(label: "spacingUnit", placeholder: "4", text: customThemeBinding(\.spacingUnit))
            } header: { Text("Spacing") }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Custom theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}
