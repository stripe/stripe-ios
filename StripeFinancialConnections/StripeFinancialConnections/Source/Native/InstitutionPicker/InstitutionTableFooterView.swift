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
        // Only the "Search for more banks" footer sits directly below the institution
        // list, so it's the only one that needs a divider above it matching the rows.
        showsDividerAboveContent: Bool = false,
        didSelect: @escaping () -> Void
    ) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        let institutionCellView = InstitutionCellView(appearance: appearance)
        let iconView = RoundedIconView(
            image: .image(image),
            style: .rounded,
            appearance: appearance,
            // match the size of the institution icons above this row
            diameter: 44
        )
        if appearance.colors == .link {
            iconView.backgroundColor = FinancialConnectionsAppearance.Colors.iconBackgroundOnCard
        }
        institutionCellView.customize(
            iconView: iconView,
            title: title,
            subtitle: subtitle
        )

        let contentView: UIView
        if appearance.colors == .link && showsDividerAboveContent {
            // `institutionCellView` sits in a `tableFooterView`, which the table view
            // does not draw its row separator above, so add one to match the rows above.
            let verticalStackView = UIStackView(
                arrangedSubviews: [
                    CreateDividerView(),
                    institutionCellView,
                ]
            )
            verticalStackView.axis = .vertical
            contentView = verticalStackView
        } else {
            contentView = institutionCellView
        }

        if appearance.colors == .link {
            backgroundColor = appearance.colors.iconBackground
            layer.cornerRadius = 12
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            layer.masksToBounds = true
        }

        addAndPinSubview(contentView)

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

private func CreateDividerView() -> UIView {
    let dividerView = UIView()
    dividerView.backgroundColor = FinancialConnectionsAppearance.Colors.dividerOnCard
    dividerView.translatesAutoresizingMaskIntoConstraints = false

    let containerView = UIView()
    containerView.addSubview(dividerView)
    let hairline = 3.0 / UIScreen.main.nativeScale
    NSLayoutConstraint.activate([
        dividerView.heightAnchor.constraint(equalToConstant: hairline),
        dividerView.topAnchor.constraint(equalTo: containerView.topAnchor),
        dividerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        // matches the `InstitutionTableView` row separator inset, so the line
        // starts below where the row titles start (past the icon)
        dividerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 72),
        dividerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
    ])
    return containerView
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
