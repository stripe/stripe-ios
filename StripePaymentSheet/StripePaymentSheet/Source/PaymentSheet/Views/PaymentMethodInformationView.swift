//
//  PaymentMethodInformationView.swift
//  StripePaymentSheet
//
//

@_spi(STP) import StripeUICore
@_spi(STP) import StripePayments
import UIKit


@objc(STP_Internal_PaymentMethodInformation)
class PaymentMethodInformationView: UIView {

    private let appearance: PaymentSheet.Appearance
    private let paymentMethod: STPPaymentMethod

    lazy var paymentMethodImage: UIImageView = {
        return UIImageView(image: paymentMethod.makeCarouselImage(for: self))
    }()

    lazy var paymentMethodLabelPrimary: UILabel = {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 15)
        label.textColor = appearance.colors.text
        label.numberOfLines = 0
        label.text = primaryText()
        return label
    }()

    lazy var paymentMethodLabelSecondary: UILabel = {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 15)
        label.textColor = appearance.colors.textSecondary
        label.numberOfLines = 0
        label.text = secondaryText()
        return label
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        self.paymentMethod = paymentMethod

        super.init(frame: .zero)
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func installConstraints() {
        let defaultPadding: CGFloat = 5.0
        [paymentMethodImage,
         paymentMethodLabelPrimary,
         paymentMethodLabelSecondary].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            paymentMethodImage.topAnchor.constraint(equalTo: topAnchor),
            paymentMethodImage.bottomAnchor.constraint(equalTo: bottomAnchor),
            paymentMethodImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -defaultPadding),
            paymentMethodLabelPrimary.leadingAnchor.constraint(equalTo: paymentMethodImage.trailingAnchor, constant: defaultPadding),
            paymentMethodLabelPrimary.centerYAnchor.constraint(equalTo: paymentMethodImage.centerYAnchor),

            paymentMethodLabelSecondary.leadingAnchor.constraint(equalTo: paymentMethodLabelPrimary.trailingAnchor, constant: defaultPadding),
            paymentMethodLabelSecondary.centerYAnchor.constraint(equalTo: paymentMethodImage.centerYAnchor)

        ])
    }

    func primaryText() -> String {
        return paymentMethod.paymentSheetLabel
    }
    func secondaryText() -> String {
        if let expMonth =  paymentMethod.card?.expMonth,
           let expYear = paymentMethod.card?.expYear {
            return "\(expMonth)/\(expYear)"
        }
        return ""
    }

}
