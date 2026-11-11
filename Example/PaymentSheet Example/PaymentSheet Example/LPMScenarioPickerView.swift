//
//  LPMScenarioPickerView.swift
//  PaymentSheet Example
//

@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentSheet
import SwiftUI

/// Lists every payment method PaymentSheet supports and applies the playground settings that offer it on its own.
struct LPMScenarioPickerView: View {
    let settings: PaymentSheetTestPlaygroundSettings
    let onSelect: (LPMScenario) -> Void
    let onCancel: () -> Void
    @State private var searchText = ""

    private static let sortedScenarios = LPMScenario.all.sorted {
        $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
    }

    /// Payment methods PaymentSheet supports that don't have a scenario yet
    private static let missingPaymentMethodTypes: [String] = {
        let covered = Set(LPMScenario.all.map(\.paymentMethodType))
        return PaymentSheet.supportedPaymentMethods.filter { !covered.contains($0) }.map(\.identifier)
    }()

    private var filteredScenarios: [LPMScenario] {
        guard !searchText.isEmpty else { return Self.sortedScenarios }
        return Self.sortedScenarios.filter { scenario in
            [scenario.displayName, scenario.id, scenario.merchantCountry.rawValue, scenario.currency.rawValue]
                .contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(filteredScenarios) { scenario in
                        Button {
                            onSelect(scenario)
                        } label: {
                            row(for: scenario)
                        }
                        .accessibilityIdentifier("lpm_scenario_\(scenario.id)")
                    }
                } footer: {
                    if searchText.isEmpty {
                        Text("Sets the merchant, currency, and amount, and turns off automatic payment methods so the selected payment method is the only one offered.")
                    }
                }
                if !Self.missingPaymentMethodTypes.isEmpty {
                    Section("No scenario yet") {
                        Text(Self.missingPaymentMethodTypes.joined(separator: ", "))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Name, type, merchant, or currency")
            .autocorrectionDisabled()
            .navigationTitle("LPM Scenarios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }

    private func row(for scenario: LPMScenario) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario.displayName)
                    .foregroundColor(.primary)
                Text("\(scenario.id) · \(scenario.summary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if scenario.isApplied(to: settings) {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
    }
}
