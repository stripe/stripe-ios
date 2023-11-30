//
//  CVCPaymentMethodInformationView.swift
//  StripePaymentSheet
//
//

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

class CVCPaymentMethodInformationView: UIView {

    private let appearance: PaymentSheet.Appearance
    private let paymentMethod: STPPaymentMethod

    lazy var paymentMethodImage: UIImageView = {
        return UIImageView(image: paymentMethod.makeIcon())
    }()

    lazy var paymentMethodLabelPrimary: UILabel = {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base, style: .body, maximumPointSize: 15)
        label.textColor = appearance.colors.componentText
        label.numberOfLines = 0
        label.text = primaryText()
        return label
    }()
    lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = appearance.colors.componentBorder
        return view
    }()

    lazy var transparentMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = transparentMaskViewBackgroundColor()
        view.layer.cornerRadius = appearance.cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        return view
    }()

    init(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        self.paymentMethod = paymentMethod

        super.init(frame: .zero)
        installConstraints()

        self.backgroundColor = appearance.colors.componentBackground
        self.layer.cornerRadius = appearance.cornerRadius
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func installConstraints() {
        let defaultPadding: CGFloat = 5.0
        [transparentMaskView,
         paymentMethodImage,
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

            transparentMaskView.leadingAnchor.constraint(equalTo: leadingAnchor),
            transparentMaskView.trailingAnchor.constraint(equalTo: trailingAnchor),
            transparentMaskView.topAnchor.constraint(equalTo: topAnchor),
            transparentMaskView.bottomAnchor.constraint(equalTo: bottomAnchor),

        ])
    }

    #if !STP_BUILD_FOR_VISION
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.transparentMaskView.backgroundColor = transparentMaskViewBackgroundColor()
    }
    #endif

    func transparentMaskViewBackgroundColor() -> UIColor {
        let alpha: CGFloat = 0.075
        let colorMaskForLight = UIColor.black.withAlphaComponent(alpha)
        let colorMaskForDark = UIColor.white.withAlphaComponent(alpha)

        return appearance.colors.componentBackground.isBright
        ? UIColor.dynamic(light: colorMaskForLight,
                          dark: colorMaskForDark)
        : UIColor.dynamic(light: colorMaskForDark,
                          dark: colorMaskForLight)
    }

    func primaryText() -> String {
        return paymentMethod.paymentSheetLabel
    }
}
