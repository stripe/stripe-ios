//
//  LinkFullConsent-FooterView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/24/25.
//

@_spi(STP) import StripeUICore
import UIKit

protocol LinkFullConsentFooterViewDelegate: AnyObject {
    func footerViewDidTapReject(_ footerView: LinkFullConsentFooterView)
    func footerViewDidTapConsent(_ footerView: LinkFullConsentFooterView)
}

final class LinkFullConsentFooterView: UIView {
    private static let buttonHeight: CGFloat = 56
    private static let buttonSpacing: CGFloat = 12

    weak var delegate: LinkFullConsentFooterViewDelegate?

    private let allowButtonLabel: String
    private let denyButtonLabel: String?
    private let disclaimer: String?

    private lazy var disclaimerLabel: UILabel? = {
        guard let disclaimer else { return nil }
        let label = UILabel()
        label.text = disclaimer
        label.font = LinkUI.font(forTextStyle: .caption)
        label.textColor = .linkTextSecondary
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var consentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(allowButtonLabel, for: .normal)
        button.setTitleColor(.linkSurfacePrimary, for: .normal)
        button.titleLabel?.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        button.backgroundColor = .linkTextPrimary
        button.layer.cornerRadius = LinkUI.cornerRadius
        button.heightAnchor.constraint(equalToConstant: Self.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(consentButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var rejectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(denyButtonLabel, for: .normal)
        button.setTitleColor(.linkTextPrimary, for: .normal)
        button.titleLabel?.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        button.backgroundColor = .linkSurfaceSecondary
        button.layer.cornerRadius = LinkUI.cornerRadius
        button.heightAnchor.constraint(equalToConstant: Self.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Self.buttonSpacing
        stackView.distribution = .fillEqually

        if denyButtonLabel != nil {
            stackView.addArrangedSubview(rejectButton)
            stackView.addArrangedSubview(consentButton)
        } else {
            stackView.addArrangedSubview(consentButton)
        }

        return stackView
    }()

    private lazy var containerStackView: UIStackView = {
        var arrangedSubviews: [UIView] = []

        if let disclaimerLabel {
            arrangedSubviews.append(disclaimerLabel)
        }
        arrangedSubviews.append(buttonsStackView)

        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.spacing = LinkUI.contentSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = LinkUI.contentMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(viewModel: LinkConsentViewModel.FullConsentViewModel) {
        self.allowButtonLabel = viewModel.allowButtonLabel
        self.denyButtonLabel = viewModel.denyButtonLabel
        self.disclaimer = viewModel.disclaimer
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .linkSurfacePrimary
        addAndPinSubview(containerStackView)
    }

    @objc private func rejectButtonTapped() {
        delegate?.footerViewDidTapReject(self)
    }

    @objc private func consentButtonTapped() {
        delegate?.footerViewDidTapConsent(self)
    }
}
