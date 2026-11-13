//
//  FlowStepContainerView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/28/26.
//

import SwiftUI

/// A shared layout for a flow step with optional screen content and a primary action.
struct FlowStepContainerView<Content: View>: View {
    private let navigationTitle: LocalizedStringKey
    private let systemImageName: String
    private let title: LocalizedStringKey
    private let message: LocalizedStringKey
    private let buttonTitle: LocalizedStringKey
    private let isButtonDisabled: Bool
    private let action: () -> Void
    private let content: Content

    @Environment(\.isLoading) private var isLoading

    /// Creates a flow step with a header, optional content, and a bottom action.
    /// - Parameters:
    ///   - navigationTitle: The title displayed in the navigation bar.
    ///   - systemImageName: The SF Symbol displayed above the heading.
    ///   - title: The step's heading.
    ///   - message: The explanation below the heading.
    ///   - buttonTitle: The primary action's label.
    ///   - isButtonDisabled: Whether the primary action is unavailable. Defaults to `false`.
    ///   - action: Called when the primary action is selected.
    ///   - content: Additional content below the explanation. Defaults to an empty view.
    init(
        navigationTitle: LocalizedStringKey,
        systemImageName: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        buttonTitle: LocalizedStringKey,
        isButtonDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.navigationTitle = navigationTitle
        self.systemImageName = systemImageName
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.isButtonDisabled = isButtonDisabled
        self.action = action
        self.content = content()
    }

    // MARK: - View

    var body: some View {
        FoldAvoidingScrollView(alignment: .top, avoidsHorizontalFolds: false) { _ in
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: systemImageName)
                    .font(.largeTitle)
                    .padding()
                    .background {
                        Color(.systemGroupedBackground)
                            .cornerRadius(16)
                    }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                content
            }
            .horizontallyCenteredContent()
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            Button(buttonTitle, action: action)
                .buttonStyle(PrimaryButtonStyle())
                .horizontallyCenteredContent()
                .disabled(isButtonDisabled || isLoading.wrappedValue)
                .opacity(isButtonDisabled || isLoading.wrappedValue ? 0.5 : 1)
                .padding()
                .background(.background)
                .avoidingActiveFold()
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
