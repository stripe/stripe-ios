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
            textColor: .textDefault
        )
        titleLabel.textAlignment = .center
        titleLabel.setText("No results") // TODO(kgaidis): localize title
        verticalStackView.addArrangedSubview(titleLabel)
        
        let subtitleLabel = AttributedTextView(
            font: .body(.medium),
            boldFont: .body(.mediumEmphasized),
            linkFont: .body(.mediumEmphasized),
            textColor: .textDefault,
            linkColor: .textActionPrimaryFocused,
            showLinkUnderline: false,
            alignCenter: true
        )
        if let didSelectManuallyEnterDetails = didSelectManuallyEnterDetails {
            let subtitleText = "Try searching another bank or %@"
            let manuallyEnterDetailsText = "manually enter details"
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
            subtitleLabel.setText("Try searching another bank")
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
            .frame(maxHeight: 100)
            
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
