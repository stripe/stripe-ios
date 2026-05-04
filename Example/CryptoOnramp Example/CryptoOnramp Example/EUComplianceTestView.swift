//
//  EUComplianceTestView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 4/27/26.
//

import SwiftUI
import UIKit

@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

/// A debug view for exercising EU compliance endpoints against live API responses.
struct EUComplianceTestView: View {
    let coordinator: CryptoOnrampCoordinator

    @Environment(\.dismiss) private var dismiss
    @State private var identifiersText = ""
    @State private var responseText = "Run an action to see the response."
    @State private var errorMessage: String?
    @State private var isRunning = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Responses")
                            .font(.headline)

                        Text(responseText)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(8)

                        Button {
                            UIPasteboard.general.string = responseText
                        } label: {
                            Label("Copy Response", systemImage: "doc.on.doc")
                        }
                        .disabled(responseText.isEmpty)
                    }

                    Button {
                        retrieveMissingIdentifiers()
                    } label: {
                        Label("Retrieve Missing Identifiers", systemImage: "list.bullet.rectangle")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Submit Identifiers")
                            .font(.headline)

                        Text("Enter one identifier per line as type:value.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        FormField("Identifiers") {
                            TextEditor(text: $identifiersText)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 96)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(uiColor: .separator))
                                )
                        }

                        Button {
                            submitIdentifiers()
                        } label: {
                            Label("Submit Identifiers", systemImage: "paperplane")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    Button {
                        presentCRSCARFDeclaration()
                    } label: {
                        Label("Present CRS/CARF Declaration", systemImage: "doc.text")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if let errorMessage {
                        ErrorMessageView(message: errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle("EU Compliance Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .disabled(isRunning)
            .opacity(isRunning ? 0.5 : 1)
        }
    }

    private func retrieveMissingIdentifiers() {
        run {
            let response = try await coordinator.retrieveMissingIdentifiers()
            if identifiersText.isEmpty {
                identifiersText = response.identifiers.map { "\($0.type):" }.joined(separator: "\n")
            }
            responseText = """
            retrieveMissingIdentifiers:
              identifiers: \(response.identifiers.map { "\($0.type) (\($0.regulation.rawValue))" })
              alternatives: \(response.alternatives)
            """
        }
    }

    private func submitIdentifiers() {
        run {
            let identifiers = try parseIdentifiers(from: identifiersText)
            let response = try await coordinator.submitIdentifiers(identifiers)
            responseText = """
            submitIdentifiers:
              valid: \(response.valid)
              identifiers: \(response.identifiers.map { "\($0.type) (\($0.regulation.rawValue))" })
              alternatives: \(response.alternatives)
              invalid_identifiers: \(response.invalidIdentifiers)
            """
        }
    }

    private func presentCRSCARFDeclaration() {
        guard let presentingViewController = UIApplication.shared.findTopViewController() else {
            errorMessage = "Unable to find a view controller to present from."
            return
        }

        run {
            let result = try await coordinator.presentCRSCARFDeclaration(from: presentingViewController)
            responseText = """
            presentCRSCARFDeclaration:
              result: \(result.displayName)
            """
        }
    }

    private func run(_ operation: @escaping () async throws -> Void) {
        isRunning = true
        errorMessage = nil

        Task {
            do {
                try await operation()
            } catch {
                errorMessage = error.localizedDescription
            }
            isRunning = false
        }
    }

    private func parseIdentifiers(from text: String) throws -> [ComplianceIdentifier] {
        try text
            .components(separatedBy: .newlines)
            .enumerated()
            .compactMap { index, line in
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedLine.isEmpty else {
                    return nil
                }

                let parts = trimmedLine.split(
                    maxSplits: 1,
                    omittingEmptySubsequences: false
                ) { character in
                    character == ":" || character == ","
                }

                guard parts.count == 2 else {
                    throw InputError.invalidIdentifierLine(index + 1)
                }

                let type = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard !type.isEmpty, !value.isEmpty else {
                    throw InputError.invalidIdentifierLine(index + 1)
                }

                return ComplianceIdentifier(type: type, value: value)
            }
    }
}

private enum InputError: LocalizedError {
    case invalidIdentifierLine(Int)

    var errorDescription: String? {
        switch self {
        case let .invalidIdentifierLine(lineNumber):
            return "Invalid identifier on line \(lineNumber). Use type:value."
        }
    }
}

private extension CRSCARFDeclarationResult {
    var displayName: String {
        switch self {
        case .confirmed:
            return "confirmed"
        case .canceled:
            return "canceled"
        @unknown default:
            return "unknown"
        }
    }
}

#Preview {
    PreviewWrapperView { coordinator in
        EUComplianceTestView(coordinator: coordinator)
    }
}
