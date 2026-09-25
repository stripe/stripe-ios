//
//  QuestionnaireAnswerField.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/24/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
import SwiftUI

/// A questionnaire prompt and answer field with a floating label while editing or filled.
struct QuestionnaireAnswerField: View {

    /// The question displayed above the field.
    let question: String

    /// The answer entered by the customer.
    @Binding var answer: String

    /// The appearance used for the focused border and color scheme.
    let appearance: LinkAppearance

    /// Whether the answer field should take focus when it appears.
    var isInitiallyFocused = false

    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .caption) private var labelFontSize = Typography.bodySmall.font.pointSize
    @ScaledMetric(relativeTo: .body) private var inputFontSize = Typography.bodyLarge.font.pointSize
    @ScaledMetric(relativeTo: .caption) private var labelHeight = Typography.bodySmall.lineHeight
    @ScaledMetric(relativeTo: .body) private var inputHeight = Typography.bodyLarge.lineHeight

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question)
                .typography(.bodyMedium)

            ZStack(alignment: .topLeading) {
                TextField(question, text: $answer, prompt: Text(""))
                    .textFieldStyle(.plain)
                    .typography(.bodyLarge)
                    .frame(minHeight: inputHeight)
                    .padding(.top, labelHeight)
                    .tint(Color.textPrimary)
                    .focused($isFocused)

                Text(String.Localized.questionnaireAnswer)
                    .typography(.bodyLarge)
                    .foregroundColor(.textTertiary)
                    .lineLimit(1)
                    .frame(height: inputHeight, alignment: .leading)
                    .scaleEffect(showsFloatingLabel ? labelFontSize / inputFontSize : 1, anchor: .leading)
                    .offset(y: showsFloatingLabel ? (labelHeight - inputHeight) / 2 : labelHeight / 2)
                    .animation(.easeInOut(duration: 0.2), value: showsFloatingLabel)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 56)
            .background(isFocused ? Color.surfacePrimary : .surfaceSecondary, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(focusedBorderColor, lineWidth: 1.5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                isFocused = true
            }
        }
        .foregroundColor(.textPrimary)
        .preferredColorScheme(appearance.colorScheme)
        .onAppear {
            if isInitiallyFocused {
                isFocused = true
            }
        }
    }

    // MARK: - QuestionnaireAnswerField

    private var showsFloatingLabel: Bool {
        isFocused || !answer.isEmpty
    }

    private var focusedBorderColor: Color {
        Color(uiColor: appearance.colors?.selectedBorder ?? .textPrimary)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Empty answer", traits: .sizeThatFitsLayout) {
    QuestionnaireAnswerFieldPreview(answer: "", appearance: .previewLinkAppearance)
}

@available(iOS 17.0, *)
#Preview("Completed answer", traits: .sizeThatFitsLayout) {
    QuestionnaireAnswerFieldPreview(answer: "For investment", appearance: .previewLinkAppearance)
}

@available(iOS 17.0, *)
#Preview("Custom focus color", traits: .sizeThatFitsLayout) {
    QuestionnaireAnswerFieldPreview(answer: "No", appearance: LinkAppearance(colors: .init(selectedBorder: .systemPurple)), isInitiallyFocused: true)
}

private struct QuestionnaireAnswerFieldPreview: View {
    @State var answer: String
    let appearance: LinkAppearance
    var isInitiallyFocused = false

    // MARK: - View

    var body: some View {
        QuestionnaireAnswerField(
            question: "Why are you purchasing cryptocurrency through swapped.com?",
            answer: $answer,
            appearance: appearance,
            isInitiallyFocused: isInitiallyFocused
        )
        .padding(20)
        .background(Color.surfacePrimary)

    }
}
#endif
