//
//  LinkButton.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/9/25.
//

@_spi(STP) import StripeUICore
import SwiftUI

@available(iOS 16.0, *)
struct LinkButton: View {
    private enum Constants {
        static let contentHeight: CGFloat = 18
        static let separatorWidth: CGFloat = 1
        static let contentSpacing: CGFloat = 10
        static let emailFont: UIFont = .systemFont(ofSize: 15, weight: .medium)
            .scaled(withTextStyle: .callout, maximumPointSize: 16)
    }

    @StateObject private var viewModel: LinkButtonViewModel
    private let action: () -> Void
    private let height: CGFloat

    init(height: CGFloat = 44, viewModel: LinkButtonViewModel = LinkButtonViewModel(), action: @escaping () -> Void) {
        self.height = height
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Constants.contentSpacing) {
                SwiftUI.Image(uiImage: Image.link_logo_bw.makeImage(template: false))
                    .resizable()
                    .scaledToFit()
                    .frame(height: Constants.contentHeight)

                if let account = viewModel.account {
                    Rectangle()
                        .fill(Color(uiColor: .linkSeparatorOnPrimaryButton))
                        .frame(width: Constants.separatorWidth, height: Constants.contentHeight)

                    Text(account.email)
                        .font(Font(Constants.emailFont))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, LinkUI.contentSpacing)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color(uiColor: .linkIconBrand))
            .foregroundColor(Color(uiColor: .linkTextPrimary))
            .cornerRadius(height / 2)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
private struct LinkButtonPreview: View {
    private let viewModel = LinkButtonViewModel()

    init(
        email: String? = "jane.diaz@gmail.com",
        isRegistered: Bool = true
    ) {
        // Setup the view model with appropriate account
        if let email {
            viewModel.setAccount(Stubs.linkAccount(
                email: email,
                isRegistered: isRegistered
            ))
        } else {
            viewModel.setAccount(nil)
        }
    }

    var body: some View {
        LinkButton(viewModel: viewModel, action: {})
            .padding(.horizontal)
    }
}

@available(iOS 16.0, *)
#Preview {
    VStack(spacing: 20) {
        // Standard registered user
        LinkButtonPreview()

        // Moderately long email
        LinkButtonPreview(email: "thisemailislong@company.com")

        // Very long email
        LinkButtonPreview(email: "thisemailisreallyreallylong@company.com")

        // Unregistered user (won't show email)
        LinkButtonPreview(isRegistered: false)

        // No account
        LinkButtonPreview(email: nil)
    }
}

#endif
