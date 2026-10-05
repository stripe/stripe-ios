//
//  AdditionalKYCQuestionnaireView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/30/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// Collects the questionnaire accompanying either proof-of-address or source-of-funds documents.
struct AdditionalKYCQuestionnaireView: View {

    /// The heading for the current document requirement.
    let heading: String

    /// The appearance applied to the fields and primary action.
    let appearance: LinkAppearance

    /// The questions and draft answers retained across navigation.
    @ObservedObject var model: AdditionalKYCQuestionnaireModel

    /// Advances to document collection after required questions are answered.
    let onContinue: () -> Void

    /// Closes the entire collection flow.
    let onClose: () -> Void

    @Environment(\.colorScheme) private var inheritedColorScheme

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(heading)
                    .typography(.headingExtraLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                ForEach(model.questions, id: \.id) { question in
                    QuestionnaireAnswerField(
                        question: question.prompt,
                        answer: Binding(
                            get: { model.answers[question.id] ?? "" },
                            set: { model.setAnswer($0, for: question.id) }
                        ),
                        appearance: appearance
                    )
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: .Localized.continue, appearance: appearance, action: onContinue, isEnabled: model.canContinue)
                .padding(20)
                .background(Color.surfacePrimary)
        }
        .background(Color.surfacePrimary.ignoresSafeArea())
        .environment(\.colorScheme, appearance.colorScheme ?? inheritedColorScheme)
        .preferredColorScheme(appearance.colorScheme)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            CloseToolbarItem(action: onClose)
        }
        .accessibilityAction(.escape, onClose)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Source of funds questionnaire") {
    NavigationView {
        AdditionalKYCQuestionnaireView(
            heading: .Localized.tellUsAboutYourSourceOfFunds,
            appearance: .previewLinkAppearance,
            model: try! .init(questionnaire: .init(questions: [
                .init(id: "purchase_purpose", prompt: "Why are you purchasing cryptocurrency through swapped.com?", answerType: .freeText, required: true),
                .init(id: "third_party_advised", prompt: "Has anyone advised, or instructed, you to purchase cryptocurrency? This includes anyone who has messaged you on social media (Telegram, WhatsApp, Twitter, etc) about investing in or purchasing cryptocurrency.", answerType: .freeText, required: true),
            ])),
            onContinue: {},
            onClose: {}
        )
    }
}
#endif
