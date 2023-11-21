//
//  InstitutionSearchFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/19/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionSearchFooterView: UIView {

    private static let constantTopPadding: CGFloat = 10.0

    private let didSelect: (() -> Void)?
    private let topSeparatorView: UIView
    private let paddingStackView: UIStackView
    var showTopSeparator: Bool {
        get {
            return !topSeparatorView.isHidden
        }
        set {
            topSeparatorView.isHidden = !newValue
            paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: (showTopSeparator ? 20 : 0) + Self.constantTopPadding,
                leading: 24,
                bottom: 20,
                trailing: 24
            )
        }
    }

    init(
        title: String,
        subtitle: String,
        showIcon: Bool,
        didSelect: (() -> Void)?
    ) {
        self.didSelect = didSelect
        let topSeparatorView = UIView()
        topSeparatorView.backgroundColor = .borderNeutral
        self.topSeparatorView = topSeparatorView
        let paddingStackView = UIStackView(
            arrangedSubviews: [
                CreateRowView(
                    image: showIcon ? .add : nil,
                    title: title,
                    subtitle: subtitle
                ),
            ]
        )
        self.paddingStackView = paddingStackView
        super.init(frame: .zero)
        paddingStackView.isLayoutMarginsRelativeArrangement = true
        addAndPinSubview(paddingStackView)

        addSubview(topSeparatorView)
        topSeparatorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topSeparatorView.topAnchor.constraint(equalTo: topAnchor, constant: Self.constantTopPadding),
            topSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            topSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 24),
            topSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / stp_screenNativeScale),
        ])

        if didSelect != nil {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
            tapGestureRecognizer.delegate = self
            addGestureRecognizer(tapGestureRecognizer)
        }

        self.showTopSeparator = true
        accessibilityIdentifier = "institution_search_footer_view"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapView() {
        self.didSelect?()
    }
}

// MARK: - UITapGestureRecognizer

extension InstitutionSearchFooterView: UIGestureRecognizerDelegate {

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

// MARK: - Helpers

private func CreateRowView(
    image: Image?,
    title: String,
    subtitle: String
) -> UIView {
    let horizontalStackView = UIStackView()
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    if let image = image {
        horizontalStackView.addArrangedSubview(
            CreateRowIconView(image: image)
        )
    }
    horizontalStackView.addArrangedSubview(
        CreateRowLabelView(
            title: title,
            subtitle: subtitle
        )
    )
    return horizontalStackView
}

private func CreateRowIconView(image: Image) -> UIView {
    let iconImageView = UIImageView()
    iconImageView.contentMode = .scaleAspectFit
    iconImageView.image = image.makeImage()
        .withTintColor(.textBrand)

    let iconContainerView = UIView()
    iconContainerView.backgroundColor = .brand100
    iconContainerView.layer.cornerRadius = 4
    iconContainerView.addSubview(iconImageView)

    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconContainerView.widthAnchor.constraint(equalToConstant: 36),
        iconContainerView.heightAnchor.constraint(equalToConstant: 36),

        iconImageView.heightAnchor.constraint(equalToConstant: 20),
        iconImageView.widthAnchor.constraint(equalToConstant: 20),
        iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
        iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
    ])
    return iconContainerView
}

private func CreateRowLabelView(
    title: String,
    subtitle: String
) -> UIView {
    let titleLabel = AttributedTextView(
        font: .label(.largeEmphasized),
        boldFont: .label(.largeEmphasized),
        linkFont: .label(.largeEmphasized),
        textColor: .textPrimary
    )
    titleLabel.setText(title)

    let subtitleLabel = AttributedTextView(
        font: .label(.small),
        boldFont: .label(.smallEmphasized),
        linkFont: .label(.smallEmphasized),
        textColor: .textSecondary
    )
    subtitleLabel.setText(subtitle)

    let verticalStackView = UIStackView(
        arrangedSubviews: [
            titleLabel,
            subtitleLabel,
        ]
    )
    verticalStackView.axis = .vertical
    return verticalStackView
}

#if DEBUG

import SwiftUI

private struct InstitutionSearchFooterViewUIViewRepresentable: UIViewRepresentable {

    let title: String
    let subtitle: String
    let showIcon: Bool

    func makeUIView(context: Context) -> InstitutionSearchFooterView {
        InstitutionSearchFooterView(
            title: title,
            subtitle: subtitle,
            showIcon: showIcon,
            didSelect: {}
        )
    }

    func updateUIView(_ uiView: InstitutionSearchFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

struct InstitutionSearchFooterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InstitutionSearchFooterViewUIViewRepresentable(
                title: "Don't see your bank?",
                subtitle: "Enter your bank account and routing numbers",
                showIcon: true
            )
            .frame(maxHeight: 100)
            InstitutionSearchFooterViewUIViewRepresentable(
                title: "No results",
                subtitle: "Double check your spelling and search terms",
                showIcon: false
            )
                .frame(maxHeight: 100)
            Spacer()
        }
    }
}

#endif
