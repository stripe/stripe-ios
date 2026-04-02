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

    // Binding to a custom theme field in UserDefaults. Updates theme when value changes.
    private func customThemeBinding(_ key: String) -> Binding<String> {
        return Binding(
            get: { AppSettings.shared.customThemeValue(forKey: key) },
            set: { newValue in
                AppSettings.shared.setCustomThemeValue(newValue, forKey: key)
                self.updateComponentManager()
            }
        )
    }

    // Helper that wraps TextInput and updates the theme instantly
    private func UpdateTextInput(label: String, placeholder: String, text: Binding<String>) -> some View {
        TextInput(label: label, placeholder: placeholder, text: text)
            .onChange(of: text.wrappedValue) { _ in
                updateComponentManager()
            }
    }

    var body: some View {
        List {
            Section {
                UpdateTextInput(label: "formPlaceholderTextColor", placeholder: Self.colorPlaceholder, text: customThemeBinding(AppSettings.Constants.formPlaceholderTextColor))
                UpdateTextInput(label: "inputFieldPaddingX", placeholder: "16", text: customThemeBinding(AppSettings.Constants.inputFieldPaddingX))
                UpdateTextInput(label: "inputFieldPaddingY", placeholder: "12", text: customThemeBinding(AppSettings.Constants.inputFieldPaddingY))
            } header: { Text("Form") }

            Section {
                UpdateTextInput(label: "actionPrimaryTextTransform", placeholder: Self.textTransformPlaceholder, text: customThemeBinding(AppSettings.Constants.actionPrimaryTextTransform))
                UpdateTextInput(label: "actionSecondaryTextTransform", placeholder: Self.textTransformPlaceholder, text: customThemeBinding(AppSettings.Constants.actionSecondaryTextTransform))
            } header: { Text("Action") }

            Section {
                UpdateTextInput(label: "tableRowPaddingY", placeholder: "8", text: customThemeBinding(AppSettings.Constants.tableRowPaddingY))
            } header: { Text("Table") }

            Section {
                UpdateTextInput(label: "buttonDangerColorBackground", placeholder: Self.colorPlaceholder, text: customThemeBinding(AppSettings.Constants.buttonDangerColorBackground))
                UpdateTextInput(label: "buttonDangerColorBorder", placeholder: Self.colorPlaceholder, text: customThemeBinding(AppSettings.Constants.buttonDangerColorBorder))
                UpdateTextInput(label: "buttonDangerColorText", placeholder: Self.colorPlaceholder, text: customThemeBinding(AppSettings.Constants.buttonDangerColorText))
            } header: { Text("Button danger") }

            Section {
                UpdateTextInput(label: "badgeLabelTextTransform", placeholder: Self.textTransformPlaceholder, text: customThemeBinding(AppSettings.Constants.badgeLabelTextTransform))
                UpdateTextInput(label: "badgeLabelFontWeight", placeholder: Self.fontWeightPlaceholder, text: customThemeBinding(AppSettings.Constants.badgeLabelFontWeight))
                UpdateTextInput(label: "badgeLabelFontSize", placeholder: "14", text: customThemeBinding(AppSettings.Constants.badgeLabelFontSize))
                UpdateTextInput(label: "badgePaddingY", placeholder: "2", text: customThemeBinding(AppSettings.Constants.badgePaddingY))
                UpdateTextInput(label: "badgePaddingX", placeholder: "6", text: customThemeBinding(AppSettings.Constants.badgePaddingX))
            } header: { Text("Badge label") }

            Section {
                UpdateTextInput(label: "buttonLabelTextTransform", placeholder: Self.textTransformPlaceholder, text: customThemeBinding(AppSettings.Constants.buttonLabelTextTransform))
                UpdateTextInput(label: "buttonLabelFontWeight", placeholder: Self.fontWeightPlaceholder, text: customThemeBinding(AppSettings.Constants.buttonLabelFontWeight))
                UpdateTextInput(label: "buttonLabelFontSize", placeholder: "16", text: customThemeBinding(AppSettings.Constants.buttonLabelFontSize))
                UpdateTextInput(label: "buttonPaddingY", placeholder: "4", text: customThemeBinding(AppSettings.Constants.buttonPaddingY))
                UpdateTextInput(label: "buttonPaddingX", placeholder: "8", text: customThemeBinding(AppSettings.Constants.buttonPaddingX))
            } header: { Text("Button label") }

            Section {
                UpdateTextInput(label: "spacingUnit", placeholder: "4", text: customThemeBinding(AppSettings.Constants.spacingUnit))
            } header: { Text("Spacing") }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Custom theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}
