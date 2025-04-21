//
//  BankAccountInfoView.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol BankAccountInfoViewDelegate {
    func didTapXIcon()
}

/// For internal SDK use only
@objc(STP_Internal_BankAccountInfoView)
class BankAccountInfoView: UIView {
    struct Constants {
        static let spacing: CGFloat = 12
    }
    
    private let appearance: PaymentSheet.Appearance
    private let incentive: PaymentMethodIncentive?

    private var theme: ElementsAppearance {
        appearance.asElementsTheme
    }
    private lazy var accountInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(bankNameLabel)
        stackView.addArrangedSubview(bankAccountNumberLabel)
        return stackView
    }()
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Constants.spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(accountInfoStackView)
        if let promoBadgeView {
            stackView.addArrangedSubview(promoBadgeView)
        }
        return stackView
    }()
    lazy var bankNameLabel: UILabel = {
        let label = UILabel()
        label.font = theme.fonts.subheadline.medium
        label.textColor = theme.colors.bodyText
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    lazy var bankAccountNumberLabel: UILabel = {
        let label = UILabel()
        label.font = theme.fonts.caption
        label.textColor = theme.colors.secondaryText
        label.numberOfLines = 0
        return label
    }()

    lazy var bankIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 2
        imageView.clipsToBounds = true
        imageView.tintColor = .systemGray2
        return imageView
    }()
    
    private lazy var promoBadgeView: PromoBadgeView? = {
        guard let incentive else {
            return nil
        }
        return PromoBadgeView(appearance: appearance, tinyMode: false, text: incentive.displayText)
    }()

    lazy var xIcon: UIImageView = {
        let xIcon = UIImageView(image: Image.icon_x_standalone.makeImage(template: true))
        xIcon.tintColor = .systemGray2
        xIcon.isUserInteractionEnabled = true
        return xIcon
    }()

    lazy var xIconTappableArea: UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = true
        return view
    }()

    var delegate: BankAccountInfoViewDelegate?

    override var isUserInteractionEnabled: Bool {
        didSet {
            xIconTappableArea.isUserInteractionEnabled = isUserInteractionEnabled
            updateUI()
        }
    }

    init(
        frame: CGRect,
        appearance: PaymentSheet.Appearance = .default,
        incentive: PaymentMethodIncentive? = nil
    ) {
        self.appearance = appearance
        self.incentive = incentive
        super.init(frame: frame)
        addViewComponents()
        addTouchCallbackForX()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addViewComponents() {
        bankIconImageView.translatesAutoresizingMaskIntoConstraints = false
        xIcon.translatesAutoresizingMaskIntoConstraints = false
        xIconTappableArea.translatesAutoresizingMaskIntoConstraints = false

        addSubview(bankIconImageView)
        addSubview(contentStackView)
        xIconTappableArea.addSubview(xIcon)
        addSubview(xIconTappableArea)

        NSLayoutConstraint.activate([
            bankIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            bankIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.spacing),
            
            contentStackView.leadingAnchor.constraint(equalTo: bankIconImageView.trailingAnchor, constant: Constants.spacing),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.spacing),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: xIconTappableArea.leadingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.spacing),
            
            xIconTappableArea.trailingAnchor.constraint(equalTo: trailingAnchor),
            xIconTappableArea.widthAnchor.constraint(equalToConstant: 44.0),
            xIconTappableArea.topAnchor.constraint(equalTo: topAnchor),
            xIconTappableArea.bottomAnchor.constraint(equalTo: bottomAnchor),

            xIcon.leadingAnchor.constraint(greaterThanOrEqualTo: xIconTappableArea.leadingAnchor, constant: Constants.spacing),
            xIcon.trailingAnchor.constraint(equalTo: xIconTappableArea.trailingAnchor, constant: -Constants.spacing),
            xIcon.centerYAnchor.constraint(equalTo: xIconTappableArea.centerYAnchor),
            xIcon.heightAnchor.constraint(equalToConstant: Constants.spacing),
            xIcon.widthAnchor.constraint(equalToConstant: Constants.spacing),
        ])
    }

    func addTouchCallbackForX() {
        let touchItem = UITapGestureRecognizer(target: self, action: #selector(didTapXIcon))
        xIconTappableArea.addGestureRecognizer(touchItem)
    }

    @objc func didTapXIcon() {
        self.delegate?.didTapXIcon()
    }

    func setBankName(text: String) {
        self.bankNameLabel.text = text
        bankIconImageView.image = PaymentSheetImageLibrary.bankIcon(for: PaymentSheetImageLibrary.bankIconCode(for: text))
    }

    func setLastFourOfBank(text: String) {
        self.bankAccountNumberLabel.text = text
    }
    
    func setIncentiveEligible(_ eligible: Bool) {
        promoBadgeView?.setEligible(eligible)
    }

    func updateUI() {
        bankNameLabel.textColor = theme.colors.textFieldText.disabled(!isUserInteractionEnabled)
        bankAccountNumberLabel.textColor = theme.colors.textFieldText.disabled(!isUserInteractionEnabled)
        bankIconImageView.alpha = isUserInteractionEnabled ? 1.0 : 0.5
        promoBadgeView?.alpha = isUserInteractionEnabled ? 1.0 : 0.5
        xIcon.alpha = isUserInteractionEnabled ? 1.0 : 0.5
    }
}

extension BankAccountInfoView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            self.isUserInteractionEnabled = true
        case .shouldDisableUserInteraction:
            self.isUserInteractionEnabled = false
        default:
            break
        }
    }
}
