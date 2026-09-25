//
//  DocumentInstructionsView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

import SwiftUI

/// A flat list of document requirement bullets.
struct DocumentInstructionsView: View {

    /// The instruction text for each bullet, in display order.
    let instructions: [String]

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(instructions.enumerated()), id: \.offset) { _, instruction in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .bold()
                        .accessibilityHidden(true)

                    Text(instruction)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .typography(.bodyMedium)
                .padding(.leading, 8)
            }
        }
        .foregroundColor(.textPrimary)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Proof of address instructions", traits: .sizeThatFitsLayout) {
    DocumentInstructionsView(instructions: DocumentCollectionConfiguration.preview.instructions)
        .padding(20)
        .background(Color.surfacePrimary)
}

@available(iOS 17.0, *)
#Preview("Source of funds instructions", traits: .sizeThatFitsLayout) {
    DocumentInstructionsView(instructions: DocumentCollectionConfiguration.sourceOfFundsPreview.instructions)
        .padding(20)
        .background(Color.surfacePrimary)
}
#endif
