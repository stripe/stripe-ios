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
        static let defaultButtonHeight: CGFloat = 44
        static let baseContentHeight: CGFloat = 18
        static let baseSeparatorWidth: CGFloat = 1
        static let baseContentSpacing: CGFloat = 10
        static let baseFontSize: CGFloat = 15
        static let minScaleFactor: CGFloat = 0.7
        static let maxScaleFactor: CGFloat = 1.5
    }

    @StateObject private var viewModel: LinkButtonViewModel
    private let action: () -> Void
    private let height: CGFloat

    init(height: CGFloat = Constants.defaultButtonHeight, viewModel: LinkButtonViewModel = LinkButtonViewModel(), action: @escaping () -> Void) {
        self.height = height
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.action = action
    }

    private var scaleFactor: CGFloat {
        let factor = height / Constants.defaultButtonHeight
        return min(max(factor, Constants.minScaleFactor), Constants.maxScaleFactor)
    }

    private var scaledContentHeight: CGFloat {
        Constants.baseContentHeight * scaleFactor
    }

    private var scaledSeparatorWidth: CGFloat {
        max(Constants.baseSeparatorWidth * scaleFactor, 0.5) // Ensure separator is always visible
    }

    private var scaledContentSpacing: CGFloat {
        Constants.baseContentSpacing * scaleFactor
    }

    private var scaledFont: UIFont {
        let scaledSize = Constants.baseFontSize * scaleFactor
        return UIFont.systemFont(ofSize: scaledSize, weight: .medium)
            .scaled(withTextStyle: .callout, maximumPointSize: max(scaledSize, 12))
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: scaledContentSpacing) {
                SwiftUI.Image(uiImage: Image.link_logo_bw.makeImage(template: false))
                    .resizable()
                    .scaledToFit()
                    .frame(height: scaledContentHeight)

                if let account = viewModel.account {
                    Rectangle()
                        .fill(Color(uiColor: .linkSeparatorOnPrimaryButton))
                        .frame(width: scaledSeparatorWidth, height: scaledContentHeight)

                    Text(account.email)
                        .font(Font(scaledFont))
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
