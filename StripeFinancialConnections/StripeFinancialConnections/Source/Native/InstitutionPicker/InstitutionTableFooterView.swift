//
//  InstitutionTableFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/29/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionTableFooterView: UIView {

    private let didSelect: () -> Void

    init(
        title: String,
        subtitle: String?,
        image: Image,
        appearance: FinancialConnectionsAppearance,
        didSelect: @escaping () -> Void
    ) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        let institutionCellView = InstitutionCellView(appearance: appearance)
        institutionCellView.customize(
            iconView: RoundedIconView(
                image: .image(image),
                style: .rounded,
                appearance: appearance
            ),
            title: title,
            subtitle: subtitle
        )
        addAndPinSubview(institutionCellView)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)

        accessibilityIdentifier = "institution_search_footer_view"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapView() {
        didSelect()
    }
}

// MARK: - UITapGestureRecognizer

extension InstitutionTableFooterView: UIGestureRecognizerDelegate {

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // if user taps on the footer, we always want it to be recognized
        //
        // if the keyboard is on screen, then NOT having this method
        // implemented will block the first tap in order to
        // dismiss the keyboard
        return true
    }
}

#if DEBUG

import SwiftUI

private struct InstitutionTableFooterViewUIViewRepresentable: UIViewRepresentable {

    let title: String
    let subtitle: String
    let image: Image
    let appearance: FinancialConnectionsAppearance

    func makeUIView(context: Context) -> InstitutionTableFooterView {
        InstitutionTableFooterView(
            title: title,
            subtitle: subtitle,
            image: image,
            appearance: appearance,
            didSelect: {}
        )
    }

    func updateUIView(_ uiView: InstitutionTableFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

struct InstitutionTableFooterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InstitutionTableFooterViewUIViewRepresentable(
                title: "Don't see your bank?",
                subtitle: "Enter your bank account and routing numbers",
                image: .search,
                appearance: .stripe
            )
            .frame(maxHeight: 100)

            InstitutionTableFooterViewUIViewRepresentable(
                title: "No results",
                subtitle: "Double check your spelling and search terms",
                image: .cancel_circle,
                appearance: .stripe
            )
            .frame(maxHeight: 100)

            InstitutionTableFooterViewUIViewRepresentable(
                title: "No results",
                subtitle: "Double check your spelling and search terms",
                image: .cancel_circle,
                appearance: .link
            )
            .frame(maxHeight: 100)

            Spacer()
        }
    }
}

#endif
