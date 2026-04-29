//
//  EUIdentifiersCollectionView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 4/29/26.
//

import SwiftUI

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// A simple screen for collecting missing EU identifiers before continuing to identity verification.
struct EUIdentifiersCollectionView: View {
    let coordinator: CryptoOnrampCoordinator
    let missingIdentifiers: MissingEUIdentifiers
    let onCompleted: () -> Void

    @Environment(\.isLoading) private var isLoading
    @State private var micaIdentifiers: [String: String]
    @State private var carfIdentifiers: [String: String]
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
        missingIdentifiers: MissingEUIdentifiers,
        onCompleted: @escaping () -> Void
    ) {
        self.coordinator = coordinator
        self.missingIdentifiers = missingIdentifiers
        self.onCompleted = onCompleted
        _micaIdentifiers = State(initialValue: Dictionary(uniqueKeysWithValues: missingIdentifiers.missingIdentifiersMICA.map { ($0, "") }))
        _carfIdentifiers = State(initialValue: Dictionary(uniqueKeysWithValues: missingIdentifiers.missingIdentifiersCARF.map { ($0, "") }))
    }

    private var isSubmitButtonDisabled: Bool {
        isLoading.wrappedValue
            || micaCountries.contains { micaIdentifiers[$0, default: ""].isEmpty }
            || carfCountries.contains { carfIdentifiers[$0, default: ""].isEmpty }
    }

    private var micaCountries: [String] {
        missingIdentifiers.missingIdentifiersMICA
    }

    private var carfCountries: [String] {
        missingIdentifiers.missingIdentifiersCARF
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
                    Text("Add EU identifiers")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Link needs a few identifiers before you can continue.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(micaCountries, id: \.self) { country in
                    FormField("MICA identifier for \(country)") {
                        TextField("Enter identifier", text: micaBinding(for: country))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
                }

                ForEach(carfCountries, id: \.self) { country in
                    FormField("CRS/CARF TIN for \(country)") {
                        TextField("Enter tax identifier", text: carfBinding(for: country))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
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
        .navigationTitle("EU Identifiers")
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

    private func micaBinding(for country: String) -> Binding<String> {
        Binding(
            get: { micaIdentifiers[country, default: ""] },
            set: { micaIdentifiers[country] = $0 }
        )
    }

    private func carfBinding(for country: String) -> Binding<String> {
        Binding(
            get: { carfIdentifiers[country, default: ""] },
            set: { carfIdentifiers[country] = $0 }
        )
    }

    private func submitIdentifiers() {
        isLoading.wrappedValue = true
        alert = nil

        let identifiers = EUIdentifiers(
            mica: micaCountries.map { country in
                EUIdentifier(country: country, identifier: micaIdentifiers[country, default: ""])
            },
            carf: carfCountries.map { country in
                EUIdentifier(country: country, identifier: carfIdentifiers[country, default: ""])
            }
        )

        Task {
            do {
                let result = try await coordinator.submitEUIdentifiers(identifiers: identifiers)
                await MainActor.run {
                    isLoading.wrappedValue = false
                    if result.valid {
                        onCompleted()
                    } else {
                        alert = Alert(title: "EU identifiers need attention", message: errorMessage(for: result))
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading.wrappedValue = false
                    alert = Alert(title: "EU identifier submission failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func errorMessage(for result: SubmitEUIdentifiersResult) -> String {
        let missingMICA = result.missingIdentifiers?.missingIdentifiersMICA ?? []
        let missingCARF = result.missingIdentifiers?.missingIdentifiersCARF ?? []
        let errors = result.errors ?? []

        return """
        Some identifiers need to be corrected.
        Missing MICA: \(missingMICA)
        Missing CRS/CARF: \(missingCARF)
        Errors: \(errors)
        """
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        if let missingIdentifiers = try? JSONDecoder().decode(
            MissingEUIdentifiers.self,
            from: Data(#"{"missing_identifiers_mica":["EE"],"missing_identifiers_carf":["GR"]}"#.utf8)
        ) {
            EUIdentifiersCollectionView(
                coordinator: coordinator,
                missingIdentifiers: missingIdentifiers,
                onCompleted: {}
            )
        }
    }
}
