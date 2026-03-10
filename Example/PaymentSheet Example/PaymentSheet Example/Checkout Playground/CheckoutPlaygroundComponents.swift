//
//  CheckoutPlaygroundComponents.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import SwiftUI

@available(iOS 15.0, *)
extension CheckoutPlayground {
    struct SectionHeader: View {
        let title: String
        let icon: String

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text(title.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 4)
            .padding(.bottom, 4)
        }
    }

    struct PickerRow<T: Hashable & RawRepresentable & CaseIterable>: View where T.RawValue == String, T: Identifiable {
        let title: String
        let icon: String
        @Binding var selection: T
        var tooltip: String?
        var displayText: ((T) -> String)?

        var body: some View {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .frame(width: 24)
                        .foregroundColor(.blue)

                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    if let tooltip = tooltip {
                        InfoButton(title: title, message: tooltip)
                    }
                }

                Spacer()
                Picker(title, selection: $selection) {
                    ForEach(Array(T.allCases), id: \.self) { value in
                        Text(displayText?(value) ?? value.rawValue.capitalized).tag(value)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accentColor(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
    }

    struct ToggleRow: View {
        let title: String
        @Binding var isOn: Bool
        var tooltip: String?

        var body: some View {
            HStack {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.body)

                    if let tooltip = tooltip {
                        InfoButton(title: title, message: tooltip)
                    }
                }
                Spacer()
                Toggle(title, isOn: $isOn)
                    .labelsHidden()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
    }

    struct InfoButton: View {
        let title: String
        let message: String
        @State private var showInfo = false

        var body: some View {
            Button {
                showInfo = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .alert(title, isPresented: $showInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(message)
            }
        }
    }

    struct ErrorBanner: View {
        let message: String
        let onDismiss: () -> Void

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 22))
                }
            }
            .padding(16)
            .background(Color.red.opacity(0.08))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
    }

    struct CreateButtonBar: View {
        let isCreating: Bool
        let isDisabled: Bool
        let onCreate: () -> Void

        var body: some View {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemGroupedBackground).opacity(0),
                        Color(uiColor: .systemGroupedBackground),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                VStack {
                    Button(action: onCreate) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                                Text("Creating Session...")
                                    .fontWeight(.semibold)
                            } else {
                                Text("Create Checkout Session")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isDisabled ? Color.secondary : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isDisabled)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
    }
}
