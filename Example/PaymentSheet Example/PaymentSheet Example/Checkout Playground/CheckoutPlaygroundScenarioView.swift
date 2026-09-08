//
//  CheckoutPlaygroundScenarioView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 9/8/26.

import SwiftUI

struct CheckoutPlaygroundScenarioView: View {
    let groups: [CheckoutPlayground.ScenarioGroup]
    let onRun: (CheckoutPlayground.Scenario) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    header
                        .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20))
                }

                Section("Choose a category") {
                    ForEach(groups) { group in
                        NavigationLink {
                            CheckoutPlaygroundScenarioGroupView(group: group, onRun: run)
                        } label: {
                            CheckoutPlaygroundScenarioGroupRow(group: group)
                        }
                        .accessibilityIdentifier("checkout_scenario_group_\(group.id)")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Run a scenario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "play.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text("Repeatable test configurations")
                    .font(.headline)
                Text("Choosing a scenario replaces the current settings and creates a Checkout Session.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func run(_ scenario: CheckoutPlayground.Scenario) {
        onRun(scenario)
        dismiss()
    }
}

private struct CheckoutPlaygroundScenarioGroupView: View {
    let group: CheckoutPlayground.ScenarioGroup
    let onRun: (CheckoutPlayground.Scenario) -> Void

    var body: some View {
        List {
            Section {
                Text(group.detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
            }

            if !group.groups.isEmpty {
                Section("Categories") {
                    ForEach(group.groups) { child in
                        NavigationLink {
                            CheckoutPlaygroundScenarioGroupView(group: child, onRun: onRun)
                        } label: {
                            CheckoutPlaygroundScenarioGroupRow(group: child)
                        }
                        .accessibilityIdentifier("checkout_scenario_group_\(child.id)")
                    }
                }
            }

            if !group.scenarios.isEmpty {
                Section("Scenarios") {
                    ForEach(group.scenarios, id: \.id) { scenario in
                        Button {
                            onRun(scenario)
                        } label: {
                            CheckoutPlaygroundScenarioRow(scenario: scenario, tint: group.style.tint)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("checkout_scenario_\(scenario.id)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(group.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CheckoutPlaygroundScenarioGroupRow: View {
    let group: CheckoutPlayground.ScenarioGroup

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: group.style.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(group.style.tint)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(group.title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                Text("\(group.scenarioCount) \(group.scenarioCount == 1 ? "scenario" : "scenarios")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct CheckoutPlaygroundScenarioRow: View {
    let scenario: CheckoutPlayground.Scenario
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                Text(scenario.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Image(systemName: "play.circle.fill")
                .font(.system(size: 25))
                .foregroundColor(tint)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 5)
    }
}

private extension CheckoutPlayground.ScenarioGroup.Style {
    var icon: String {
        switch self {
        case .localPaymentMethods: return "globe.americas.fill"
        case .tax: return "percent"
        case .savedPaymentMethods: return "person.crop.circle.badge.checkmark"
        case .elements: return "square.grid.2x2.fill"
        case .region: return "folder.fill"
        }
    }

    var tint: Color {
        switch self {
        case .localPaymentMethods: return .blue
        case .tax: return .orange
        case .savedPaymentMethods: return .purple
        case .elements: return .teal
        case .region: return .blue
        }
    }
}
