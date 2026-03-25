//
//  InstitutionNoResultsView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/29/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionNoResultsView: UIView {

    private let didSelectManuallyEnterDetails: (() -> Void)?

    init(
        appearance: FinancialConnectionsAppearance,
        didSelectManuallyEnterDetails: (() -> Void)?
    ) {
        self.didSelectManuallyEnterDetails = didSelectManuallyEnterDetails
        super.init(frame: .zero)

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 24,
            leading: 24,
            bottom: 0,
            trailing: 24
        )

        let titleLabel = AttributedLabel(
            font: .heading(.large),
            textColor: FinancialConnectionsAppearance.Colors.textDefault
        )
        titleLabel.textAlignment = .center
        titleLabel.setText(
            STPLocalizedString(
                "No results",
                "The title of a notice that appears at the bottom of search results. It appears when a user is searching for their bank, but no results are returned."
            )
        )
        verticalStackView.addArrangedSubview(titleLabel)

        let subtitleLabel = AttributedTextView(
            font: .body(.medium),
            boldFont: .body(.mediumEmphasized),
            linkFont: .body(.mediumEmphasized),
            textColor: FinancialConnectionsAppearance.Colors.textDefault,
            linkColor: appearance.colors.textAction,
            showLinkUnderline: false,
            alignment: .center
        )
        subtitleLabel.accessibilityIdentifier = "institution_search_no_results_subtitle"
        if let didSelectManuallyEnterDetails = didSelectManuallyEnterDetails {
            let subtitleText = STPLocalizedString(
                "Try searching another bank or %@",
                "Part of a subtitle of a notice that appears at the bottom of search results. It appears when a user is searching for their bank, but no results are returned. The '%@' will be replaced by a tappable text that says: 'manually enter details'."
            )
            let manuallyEnterDetailsText = STPLocalizedString(
                "manually enter details",
                "Part of a subtitle of a notice that appears at the bottom of search results. It appears when a user is searching for their bank, but no results are returned. This part of the notice will be tappable. Tapping this will allow a user to manually enter their bank details (account and routing numbers)."
            )
            subtitleLabel.setText(
                String(
                    format: subtitleText,
                    "[\(manuallyEnterDetailsText)](stripe://this-url-will-be-ignored)"
                ),
                action: { _ in
                    didSelectManuallyEnterDetails()
                }
            )
        } else {
            subtitleLabel.setText(
                STPLocalizedString(
                    "Try searching another bank",
                    "The subtitle of a notice that appears at the bottom of search results. It appears when a user is searching for their bank, but no results are returned."
                )
            )
        }
        verticalStackView.addArrangedSubview(subtitleLabel)

        addAndPinSubview(verticalStackView)

        accessibilityIdentifier = "institution_no_results_footer_view"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG

import SwiftUI

private struct InstitutionNoResultsViewUIViewRepresentable: UIViewRepresentable {

    let showManualEntry: Bool

    func makeUIView(context: Context) -> InstitutionNoResultsView {
        InstitutionNoResultsView(
            appearance: .stripe,
            didSelectManuallyEnterDetails: (showManualEntry ? {} : nil)
        )
    }

    func updateUIView(_ uiView: InstitutionNoResultsView, context: Context) {
        uiView.sizeToFit()
    }
}

struct InstitutionNoResultsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InstitutionNoResultsViewUIViewRepresentable(
                showManualEntry: true
            )
            .frame(maxHeight: 140)

            InstitutionNoResultsViewUIViewRepresentable(
                showManualEntry: false
            )
            .frame(maxHeight: 100)

            Spacer()
        }
        .padding()
        .padding()
    }
}

#endif
