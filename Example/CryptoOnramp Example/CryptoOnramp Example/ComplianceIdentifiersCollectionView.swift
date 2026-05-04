//
//  ComplianceIdentifiersCollectionView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 4/30/26.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// A simple screen for collecting missing compliance identifiers before continuing to identity verification.
struct ComplianceIdentifiersCollectionView: View {
    private struct IdentifierInputState: Hashable {
        let requirement: ComplianceIdentifierRequirement
        var selectedType: ComplianceIdentifierType
        var value: String
    }

    let coordinator: CryptoOnrampCoordinator
    let onCompleted: () -> Void

    @Environment(\.isLoading) private var isLoading
    @State private var identifierInputs: [IdentifierInputState]
    @State private var alternatives: [ComplianceIdentifierAlternativeGroup]
    @State private var alert: Alert?

    private var isPresentingAlert: Binding<Bool> {
        Binding(get: {
            alert != nil
        }, set: { newValue in
            if !newValue {
                alert = nil
            }
        })
    }

    init(
        coordinator: CryptoOnrampCoordinator,
        requirements: ComplianceIdentifierRequirements,
        onCompleted: @escaping () -> Void
    ) {
        self.coordinator = coordinator
        self.onCompleted = onCompleted
        _identifierInputs = State(
            initialValue: requirements.identifiers.map {
                IdentifierInputState(requirement: $0, selectedType: $0.type, value: "")
            }
        )
        _alternatives = State(initialValue: requirements.alternatives)
    }

    private var isSubmitButtonDisabled: Bool {
        isLoading.wrappedValue
            || identifierInputs.contains { $0.value.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "number.square")
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color(.systemGroupedBackground)
                            .cornerRadius(16)
                    }

                VStack(spacing: 6) {
                    Text("Add identifiers")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Link needs you to specify the following identifiers before you can continue.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach($identifierInputs, id: \.self) { $input in
                    identifierField(input: $input)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button("Submit Identifiers") {
                submitIdentifiers()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSubmitButtonDisabled)
            .opacity(isSubmitButtonDisabled ? 0.5 : 1)
            .padding()
        }
        .navigationTitle("Identifiers")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            alert?.title ?? "Error",
            isPresented: isPresentingAlert,
            presenting: alert,
            actions: { _ in
                Button("OK") {}
            }, message: { alert in
                Text(alert.message)
            }
        )
    }

    @ViewBuilder
    private func identifierField(input: Binding<IdentifierInputState>) -> some View {
        let requirement = input.wrappedValue.requirement
        let identifierTypeOptions = identifierTypeOptions(for: requirement)

        VStack(alignment: .leading, spacing: 8) {
            if identifierTypeOptions.count > 1 {
                Picker(
                    "Identifier type",
                    selection: input.selectedType
                ) {
                    ForEach(identifierTypeOptions, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            FormField("\(input.wrappedValue.selectedType.displayName) for \(requirement.regulation.rawValue)") {
                TextField("Enter identifier", text: input.value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
            }
        }
    }

    private func identifierTypeOptions(for requirement: ComplianceIdentifierRequirement) -> [ComplianceIdentifierType] {
        let alternativeIdentifiers = alternatives
            .first { $0.originalMissingIdentifiers.contains(requirement.type) }?
            .alternativeMissingIdentifiers ?? []

        return ([requirement.type] + alternativeIdentifiers).uniqued()
    }

    private func submitIdentifiers() {
        isLoading.wrappedValue = true
        alert = nil

        let identifiers = identifierInputs.map { input in
            ComplianceIdentifier(
                type: input.selectedType,
                value: input.value
            )
        }

        Task {
            do {
                let result = try await coordinator.submitIdentifiers(identifiers)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    if result.valid {
                        onCompleted()
                    } else {
                        updateRequirements(from: result)
                        alert = Alert(title: "Identifiers need attention", message: errorMessage(for: result))
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "Identifier submission failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func updateRequirements(from result: SubmitIdentifiersResult) {
        alternatives = result.alternatives
        identifierInputs = result.identifiers.map { requirement in
            let existingInput = identifierInputs.first { $0.requirement.type == requirement.type }
            return IdentifierInputState(
                requirement: requirement,
                selectedType: existingInput?.selectedType ?? requirement.type,
                value: existingInput?.value ?? ""
            )
        }
    }

    private func errorMessage(for result: SubmitIdentifiersResult) -> String {
        let identifiers = result.identifiers.map { "\($0.type.displayName) (\($0.regulation.rawValue))" }
        let invalidIdentifiers = result.invalidIdentifiers.map(\.displayName)

        return """
        Some identifiers need to be corrected.
        Missing identifiers: \(identifiers)
        Invalid identifiers: \(invalidIdentifiers)
        """
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        ComplianceIdentifiersCollectionView(
            coordinator: coordinator,
            requirements: ComplianceIdentifierRequirements(
                identifiers: [
                    .init(type: .deSTN, regulation: .euCARF),
                    .init(type: .mtNIC, regulation: .euMICA),
                ],
                alternatives: [
                    .init(
                        originalMissingIdentifiers: [.mtNIC],
                        alternativeMissingIdentifiers: [.mtPP]
                    ),
                ]
            ),
            onCompleted: {}
        )
    }
}
