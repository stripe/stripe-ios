//
//  LinkFullConsent-EmailView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/24/25.
//

@_spi(STP) import StripeUICore
import UIKit

final class LinkFullConsentEmailView: UIView {

    private let email: String

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.text = email
        label.font = LinkUI.font(forTextStyle: .detail)
        label.textColor = .linkTextPrimary
        label.textAlignment = .center
        return label
    }()

    init(email: String) {
        self.email = email
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .linkSurfacePrimary
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.linkSurfaceTertiary.cgColor
        addAndPinSubview(emailLabel, directionalLayoutMargins: LinkUI.compactButtonMargins)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    #if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = UIColor.linkSurfaceTertiary.cgColor
        }
    }
    #endif
}
