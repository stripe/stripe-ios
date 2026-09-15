//
//  MessageView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/10/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// A generic message UI with an icon, heading, body text, and primary action button.
struct MessageView: View {

    /// The content and appearance of a message.
    struct Configuration {

        /// The image displayed above the heading.
        var icon: SwiftUI.Image

        /// The color applied to the icon.
        var iconForeground: UIColor = .textPrimary

        /// The color applied to the circular background behind the icon.
        var iconBackground: UIColor = .surfaceSecondary

        /// The localized heading displayed below the icon.
        var heading: String

        /// The localized message displayed below the heading.
        var body: String

        /// The localized title of the primary action button.
        var primaryActionTitle: String
    }

    /// The content and appearance of the message.
    let configuration: Configuration

    /// The appearance for the screen and its primary button.
    let appearance: LinkAppearance

    /// The action invoked by the primary button.
    let onPrimaryAction: () -> Void

    /// The action invoked when the close toolbar button is pressed.
    let onClose: () -> Void

    @Environment(\.colorScheme) private var inheritedColorScheme

    // MARK: - View

    var body: some View {
        content
            .toolbar { CloseToolbarItem(action: onClose) }
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(appearance.colorScheme)
            .accessibilityAction(.escape, onClose)
    }

    private var content: some View {
        GeometryReader { geometry in
            ScrollView {
                message
                    .padding(20)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: configuration.primaryActionTitle,
                                appearance: appearance,
                                action: onPrimaryAction)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.surfacePrimary)
        }
        .background(Color.surfacePrimary.ignoresSafeArea())
        .environment(\.colorScheme, appearance.colorScheme ?? inheritedColorScheme)
    }

    private var message: some View {
        VStack(spacing: 0) {
            configuration.icon
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(Color(uiColor: configuration.iconForeground))
                .frame(width: 64, height: 64)
                .background(Color(uiColor: configuration.iconBackground), in: Circle())
                .accessibilityHidden(true)
                .padding(.bottom, 20)

            Text(configuration.heading)
                .typography(.headingExtraLarge)
                .foregroundColor(.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 8)

            Text(configuration.body)
                .typography(.bodyExtraLarge)
                .foregroundColor(.textTertiary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}

extension MessageView.Configuration {

    /// Creates a proof-of-address introduction.
    /// - Parameters:
    ///   - amount: The formatted monetary threshold, including its currency symbol.
    static func proofOfAddress(amount: String) -> Self {
        .init(icon: makeIcon(.iconLocationPin), heading: .Localized.uploadProofOfAddress,
              body: .Localized.proofOfAddressExplanation(amount: amount), primaryActionTitle: .Localized.continue)
    }

    /// Creates a source-of-funds introduction.
    /// - Parameters:
    ///   - amount: The formatted monetary threshold, including its currency symbol.
    static func sourceOfFunds(amount: String) -> Self {
        .init(icon: makeIcon(.iconWallet), heading: .Localized.tellUsAboutYourSourceOfFunds,
              body: .Localized.sourceOfFundsExplanation(amount: amount), primaryActionTitle: .Localized.continue)
    }

    /// A submission confirmation.
    static var submitted: Self {
        .init(icon: makeIcon(.iconClock), heading: .Localized.submittedForReview,
              body: .Localized.documentsUnderReview, primaryActionTitle: UIButton.doneButtonTitle)
    }

    /// A generic error with a close action.
    static var genericError: Self {
        .init(icon: makeIcon(.iconExclamationCircle), iconForeground: .white, iconBackground: .surfaceCritical,
              heading: .Localized.something_went_wrong, body: .Localized.tryAgainLater,
              primaryActionTitle: .Localized.close)
    }

    private static func makeIcon(_ image: Image) -> SwiftUI.Image {
        SwiftUI.Image(uiImage: image.makeImage(template: true))
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Proof of address") {
    MessageViewPreview(configuration: .proofOfAddress(amount: "€1,000"))
}

@available(iOS 17.0, *)
#Preview("Source of funds") {
    MessageViewPreview(configuration: .sourceOfFunds(amount: "€1,000"))
}

@available(iOS 17.0, *)
#Preview("Submitted for review") {
    MessageViewPreview(configuration: .submitted)
}

@available(iOS 17.0, *)
#Preview("Generic error") {
    MessageViewPreview(configuration: .genericError)
}

@available(iOS 17.0, *)
private struct MessageViewPreview: View {
    let configuration: MessageView.Configuration
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - View

    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                NavigationStack {
                    MessageView(
                        configuration: configuration,
                        appearance: .previewLinkAppearance,
                        onPrimaryAction: {},
                        onClose: {}
                    )
                }
                // Forward canvas overrides across the sheet's presentation boundary.
                .dynamicTypeSize(dynamicTypeSize)
            }
            .transaction { $0.disablesAnimations = true }
    }
}
#endif
