//
//  PaymentMethodInformationView.swift
//  StripePaymentSheet
//
//

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

@objc(STP_Internal_PaymentMethodInformation)
class PaymentMethodInformationView: UIView {

    private let appearance: PaymentSheet.Appearance
    private let paymentMethod: STPPaymentMethod

    lazy var paymentMethodImage: UIImageView = {
        return UIImageView(image: paymentMethod.makeIcon())
    }()

    lazy var paymentMethodLabelPrimary: UILabel = {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base, style: .body, maximumPointSize: 15)
        label.textColor = appearance.colors.text
        label.numberOfLines = 0
        label.text = primaryText()
        return label
    }()
    lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = appearance.colors.componentBorder
        return view
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        self.paymentMethod = paymentMethod

        super.init(frame: .zero)
        installConstraints()

        // Use disabled background if we are using default, otherwise
        // use the `.disabledColor` to add alpha to the color
        if appearance.colors.componentBackground.cgColor == UIColor.systemBackground.cgColor ||
            appearance.colors.componentBackground.cgColor == UIColor.secondarySystemBackground.cgColor {
            self.backgroundColor = appearance.asElementsTheme.colors.disabledBackground
        } else {
            self.backgroundColor = appearance.colors.componentBackground.disabledColor
        }

        self.layer.cornerRadius = appearance.cornerRadius
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func installConstraints() {
        let defaultPadding: CGFloat = 5.0
        [paymentMethodImage,
         paymentMethodLabelPrimary,
         separatorView,
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            paymentMethodImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ElementsUI.contentViewInsets.leading),
            paymentMethodImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            paymentMethodLabelPrimary.leadingAnchor.constraint(equalTo: paymentMethodImage.trailingAnchor, constant: defaultPadding),
            paymentMethodLabelPrimary.centerYAnchor.constraint(equalTo: paymentMethodImage.centerYAnchor),

            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: appearance.borderWidth),
        ])
    }

    func primaryText() -> String {
        return paymentMethod.paymentSheetLabel
    }
}
