//
//  OAuthScopeSelectionView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/20/25.
//

import SwiftUI

/// A view that allows selection of OAuth scopes for authentication.
struct OAuthScopeSelectionView: View {
    @Binding var selectedScopes: Set<OAuthScopes>
    let onOnrampScopesSelected: () -> Void
    let onAllScopesSelected: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - View

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Button("Required") {
                            onOnrampScopesSelected()
                        }

                        Button("All") {
                            onAllScopesSelected()
                        }

                        Spacer()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    VStack(spacing: 8) {
                        ForEach(OAuthScopes.allCases, id: \.self) { scope in
                            Button {
                                if selectedScopes.contains(scope) {
                                    selectedScopes.remove(scope)
                                } else {
                                    selectedScopes.insert(scope)
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedScopes.contains(scope) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedScopes.contains(scope) ? .blue : .gray)
                                        .font(.system(size: 14))

                                    Text(scope.rawValue)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedScopes.contains(scope) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding([.bottom, .horizontal])
            }
            .navigationTitle("OAuth Scopes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    #if compiler(>=6.2)
                    if #available(iOS 26.0, *) {
                        Button(role: .confirm) { dismiss() }
                    } else {
                        Button("Done") { dismiss() }
                    }
                    #else
                    Button("Done") { dismiss() }
                    #endif
                }
            }
        }
    }
}

#Preview {
    OAuthScopeSelectionView(
        selectedScopes: .constant([]),
        onOnrampScopesSelected: {},
        onAllScopesSelected: {}
    )
}
