//
//  ComplianceIdentifiersEntryView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 4/30/26.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// A simple screen for collecting missing compliance identifiers before continuing to identity verification.
struct ComplianceIdentifiersEntryView: View {
    private struct IdentifierInputState: Identifiable {
        let requirement: ComplianceIdentifierRequirement
        var selectedType: ComplianceIdentifierType
        var value: String

        var id: ComplianceIdentifierRequirement {
            requirement
        }
    }

    private struct CARFIdentifierInputState: Identifiable {
        let id = UUID()
        var selectedType: ComplianceIdentifierType
        var value: String
    }

    let coordinator: CryptoOnrampCoordinator
    let onCompleted: () -> Void

    @Environment(\.isLoading) private var isLoading
    @State private var identifierInputs: [IdentifierInputState]
    @State private var alternatives: [ComplianceIdentifierAlternativeGroup]
    @State private var isCARFTINRequired: Bool
    @State private var carfIdentifierInputs: [CARFIdentifierInputState]
    @State private var alert: Alert?

    private static let carfIdentifierTypeOptions: [ComplianceIdentifierType] = [
        .atSTN,
        .beNRN,
        .bgUCN,
        .cyTIC,
        .czRC,
        .deSTN,
        .dkCPR,
        .eeIK,
        .esNIF,
        .fiHETU,
        .frNIR,
        .frSPI,
        .grAFM,
        .hrOIB,
        .huAD,
        .iePPSN,
        .itCF,
        .ltAK,
        .luNIF,
        .lvPK,
        .mtNIC,
        .nlBSN,
        .plPESEL,
        .ptNIF,
        .roCNP,
        .sePIN,
        .siPIN,
        .skRC,
    ]

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
        _isCARFTINRequired = State(initialValue: requirements.carfTinRequired)
        _carfIdentifierInputs = State(
            initialValue: requirements.carfTinRequired ? [Self.makeEmptyCARFIdentifierInput()] : []
        )
    }

    private var isSubmitButtonDisabled: Bool {
        isLoading.wrappedValue
            || micaInputsNeedingCollection.contains { $0.value.isEmpty }
            || (isCARFTINRequired && carfIdentifierInputs.isEmpty)
            || (isCARFTINRequired && carfIdentifierInputs.contains { $0.value.isEmpty })
    }

    private var carfIdentifierTypesWithValues: Set<ComplianceIdentifierType> {
        Set(carfIdentifierInputs.filter { !$0.value.isEmpty }.map(\.selectedType))
    }

    private var micaInputsNeedingCollection: [IdentifierInputState] {
        identifierInputs.filter { !isMiCARequirementSatisfiedByCARF($0.requirement) }
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

                VStack(alignment: .leading, spacing: 32) {
                    if isCARFTINRequired {
                        carfSection
                    }

                    if !identifierInputs.isEmpty {
                        micaSection
                    }
                }
                .animation(.default, value: carfIdentifierInputs.count)
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
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
            }
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
    private var micaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MiCA Identifiers")
                    .font(.headline)

                Text("Enter the required national identifier for each MiCA requirement.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach($identifierInputs) { $input in
                if isMiCARequirementSatisfiedByCARF(input.requirement) {
                    satisfiedIdentifierField(input: $input)
                } else {
                    identifierField(input: $input)
                }
            }
        }
    }

    @ViewBuilder
    private var carfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CRS/CARF Tax Identifiers")
                    .font(.headline)

                Text("Add each EU country where you are tax-resident, then enter the corresponding tax identification number.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ForEach($carfIdentifierInputs) { $input in
                carfIdentifierField(input: $input)
            }

            Button {
                carfIdentifierInputs.append(Self.makeEmptyCARFIdentifierInput())
            } label: {
                Label("Add tax identifier", systemImage: "plus.circle")
            }
            .disabled(isLoading.wrappedValue)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func identifierField(input: Binding<IdentifierInputState>) -> some View {
        let requirement = input.wrappedValue.requirement
        let identifierTypeOptions = identifierTypeOptions(for: requirement)
        let title = input.wrappedValue.selectedType.displayName
        let placeholder = "Enter identifier for \(requirement.regulation.displayName)"

        if identifierTypeOptions.count > 1 {
            VStack(alignment: .leading, spacing: 8) {
                Picker(
                    selection: input.selectedType
                ) {
                    ForEach(identifierTypeOptions, id: \.rawValue) { type in
                        Text(type.displayName).tag(type)
                    }
                } label: {
                    Text(title)
                        .font(.headline)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                TextField(placeholder, text: input.value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
            }
        } else {
            FormField(Text(title)) {
                TextField(placeholder, text: input.value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
            }
        }
    }

    private func satisfiedIdentifierField(input: Binding<IdentifierInputState>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(input.wrappedValue.selectedType.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text("Already satisfied by a tax identifier entered on this screen.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func carfIdentifierField(input: Binding<CARFIdentifierInputState>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Picker(
                    selection: input.selectedType
                ) {
                    ForEach(Self.carfIdentifierTypeOptions, id: \.rawValue) { type in
                        Text(type.carfDisplayName).tag(type)
                    }
                } label: {
                    Text(input.wrappedValue.selectedType.carfDisplayName)
                        .font(.headline)
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                if carfIdentifierInputs.count > 1 {
                    Button(role: .destructive) {
                        carfIdentifierInputs.removeAll { $0.id == input.wrappedValue.id }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(isLoading.wrappedValue)
                }
            }

            TextField("Enter tax identifier for \(input.wrappedValue.selectedType.carfDisplayName)", text: input.value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
        }
    }

    private func identifierTypeOptions(for requirement: ComplianceIdentifierRequirement) -> [ComplianceIdentifierType] {
        let alternativeIdentifiers = alternatives
            .first { $0.originalMissingIdentifiers.contains(requirement.type) }?
            .alternativeMissingIdentifiers ?? []

        return ([requirement.type] + alternativeIdentifiers).uniqued()
    }

    private func isMiCARequirementSatisfiedByCARF(_ requirement: ComplianceIdentifierRequirement) -> Bool {
        !carfIdentifierTypesWithValues.isDisjoint(with: Set(identifierTypeOptions(for: requirement)))
    }

    private func submitIdentifiers() {
        isLoading.wrappedValue = true
        alert = nil

        let carfIdentifiers = isCARFTINRequired ? carfIdentifierInputs.map { input in
            ComplianceIdentifier(
                type: input.selectedType,
                value: input.value
            )
        } : []
        let micaIdentifiers = identifierInputs.compactMap { input -> ComplianceIdentifier? in
            guard !isMiCARequirementSatisfiedByCARF(input.requirement) else {
                return nil
            }
            return ComplianceIdentifier(
                type: input.selectedType,
                value: input.value
            )
        }
        let identifiers = carfIdentifiers + micaIdentifiers

        Task {
            do {
                let result = try await coordinator.submitIdentifiers(identifiers)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    if result.completed {
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
        isCARFTINRequired = result.carfTinRequired
        if isCARFTINRequired && carfIdentifierInputs.isEmpty {
            carfIdentifierInputs.append(Self.makeEmptyCARFIdentifierInput())
        } else if !isCARFTINRequired {
            carfIdentifierInputs = []
        }
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
        let identifiers = result.identifiers.map { "\($0.type.displayName) (\($0.regulation.displayName))" }
        let invalidIdentifiers = result.invalidIdentifiers.map(\.displayName)
        var messages = ["Some identifiers need to be corrected."]

        if result.carfTinRequired {
            messages.append("A CRS/CARF tax identifier is still required.")
        }
        if !identifiers.isEmpty {
            messages.append("Missing identifiers: \(identifiers)")
        }
        if !invalidIdentifiers.isEmpty {
            messages.append("Invalid identifiers: \(invalidIdentifiers)")
        }

        return messages.joined(separator: "\n")
    }

    private static func makeEmptyCARFIdentifierInput() -> CARFIdentifierInputState {
        CARFIdentifierInputState(selectedType: carfIdentifierTypeOptions[0], value: "")
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
        ComplianceIdentifiersEntryView(
            coordinator: coordinator,
            requirements: ComplianceIdentifierRequirements(
                identifiers: [
                    .init(type: .mtNIC, regulation: .euMiCA),
                ],
                alternatives: [
                    .init(
                        originalMissingIdentifiers: [.mtNIC],
                        alternativeMissingIdentifiers: [.mtPP]
                    ),
                ],
                carfTinRequired: true
            ),
            onCompleted: {}
        )
    }
}
