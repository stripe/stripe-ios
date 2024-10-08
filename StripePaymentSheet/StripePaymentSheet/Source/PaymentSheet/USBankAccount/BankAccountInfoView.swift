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
        static let spacingSmall: CGFloat = 8
    }

    private let theme: ElementsAppearance

    lazy var bankNameLabel: UILabel = {
        let label = UILabel()
        label.font = theme.fonts.subheadlineBold
        label.textColor = theme.colors.bodyText
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    lazy var bankAccountNumberLabel: UILabel = {
        let label = UILabel()
        label.font = theme.fonts.subheadline
        label.textColor = theme.colors.bodyText
        label.numberOfLines = 0
        return label
    }()
    
    lazy var incentiveTag: IncentiveTagView = {
        IncentiveTagView(tinyMode: true)
    }()

    lazy var bankIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 2
        imageView.clipsToBounds = true
        imageView.tintColor = .systemGray2
        return imageView
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

    init(frame: CGRect, theme: ElementsAppearance = .default) {
        self.theme = theme
        super.init(frame: frame)
        addViewComponents()
        addTouchCallbackForX()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addViewComponents() {
        bankIconImageView.translatesAutoresizingMaskIntoConstraints = false
        bankNameLabel.translatesAutoresizingMaskIntoConstraints = false
        bankAccountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        incentiveTag.translatesAutoresizingMaskIntoConstraints = false
        xIcon.translatesAutoresizingMaskIntoConstraints = false
        xIconTappableArea.translatesAutoresizingMaskIntoConstraints = false

        addSubview(bankIconImageView)
        addSubview(bankNameLabel)
        addSubview(bankAccountNumberLabel)
        addSubview(incentiveTag)
        xIconTappableArea.addSubview(xIcon)
        addSubview(xIconTappableArea)

        NSLayoutConstraint.activate([
            bankIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            bankIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.spacing),

            bankNameLabel.leadingAnchor.constraint(equalTo: bankIconImageView.trailingAnchor, constant: Constants.spacing),
            bankNameLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.5),
            bankNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constants.spacing),

            bankAccountNumberLabel.leadingAnchor.constraint(equalTo: bankIconImageView.trailingAnchor, constant: Constants.spacing),
            bankAccountNumberLabel.topAnchor.constraint(equalTo: bankNameLabel.bottomAnchor, constant: Constants.spacingSmall),
            bankAccountNumberLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.spacing),
            
            incentiveTag.leadingAnchor.constraint(equalTo: bankAccountNumberLabel.trailingAnchor, constant: Constants.spacing),
            incentiveTag.topAnchor.constraint(equalTo: bankAccountNumberLabel.topAnchor, constant: Constants.spacing),
            incentiveTag.bottomAnchor.constraint(equalTo: bankAccountNumberLabel.bottomAnchor, constant: -Constants.spacing),

            xIconTappableArea.leadingAnchor.constraint(greaterThanOrEqualTo: bankAccountNumberLabel.trailingAnchor, constant: Constants.spacing),
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

    func setBankName(text: String?) {
        self.bankNameLabel.isHidden = text == nil
        self.bankNameLabel.text = text
        bankIconImageView.image = PaymentSheetImageLibrary.bankIcon(for: PaymentSheetImageLibrary.bankIconCode(for: text))
    }
    
    func setIncentive(_ incentive: String?) {
        if let incentive {
            self.incentiveTag.isHidden = false
            self.incentiveTag.setText("Get \(incentive)")
        } else {
            self.incentiveTag.isHidden = true
        }
    }

    func setLastFourOfBank(text: String) {
        self.bankAccountNumberLabel.text = text
    }

    func updateUI() {
        bankNameLabel.textColor = theme.colors.textFieldText.disabled(!isUserInteractionEnabled)
        bankAccountNumberLabel.textColor = theme.colors.textFieldText.disabled(!isUserInteractionEnabled)
        bankIconImageView.alpha = isUserInteractionEnabled ? 1.0 : 0.5
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
