//
//  HeaderIconView.swift
//  StripeIdentity
//
//  Created by Jaime Park on 2/1/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore


/*
 This view will contain the icons that will be above a banner type header view.
 Here are the two types of icon views:

 Brand icon + Stripe icon
 +------------------------+
 | +---+   +---+          |
 | | B | + | S |          |
 | +---+   +---+          |
 +------------------------+

 A singular icon (i.e. error icon)
 +------------------------+
 | +---+                  |
 | | B |                  |
 | +---+                  |
 +------------------------+
 */
class HeaderIconView: UIView {
    struct Styling {
        static let baseIconLength: CGFloat = 32
        static let cornerRadius: CGFloat = 8
        static let heightConstraint: CGFloat = 32

        static let plusIconTintColor: UIColor = CompatibleColor.label
        static let plusIconLength: CGFloat = 16

        static let shadowConfig = ShadowConfiguration(
            shadowColor: .black,
            shadowOffset: CGSize(width: 0, height: 2),
            shadowOpacity: 0.12,
            shadowRadius: 1.0
        )

        static let stackViewPadding: CGFloat = 2
        static let stackViewSpacing: CGFloat = 16
    }

    struct ViewModel {
        enum IconType {
            case brand
            case plain
        }

        let iconType: IconType
        let iconImage: UIImage
    }

    // MARK: Views
    private let baseIconView: ShadowedCorneredImageView = ShadowedCorneredImageView()

    private let plusIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.tintColor = Styling.plusIconTintColor
        imageView.image = Image.iconAdd.makeImage(template: true)
        return imageView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = Styling.stackViewSpacing
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()

    private lazy var stripeIconView: ShadowedCorneredImageView = {
        let view = ShadowedCorneredImageView(
            with: .init(
                image: StripeUICore.Image.brand_stripe.makeImage(),
                cornerRadius: Styling.cornerRadius,
                shadowConfiguration: Styling.shadowConfig
            )
        )

        return view
    }()


    // MARK: - Inits
    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel) {
        baseIconView.configure(viewModel:
                                .init(image: viewModel.iconImage,
                                      cornerRadius: Styling.cornerRadius,
                                      shadowConfiguration: Styling.shadowConfig))

        switch viewModel.iconType {
        case .brand:
            plusIconView.isHidden = false
            stripeIconView.isHidden = false
        case .plain:
            plusIconView.isHidden = true
            stripeIconView.isHidden = true
        }
    }
}

private extension HeaderIconView {
    func installViews() {
        stackView.addArrangedSubview(baseIconView)
        stackView.addArrangedSubview(plusIconView)
        stackView.addArrangedSubview(stripeIconView)
        addSubview(stackView)
    }

    func installConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Set the base icon view's static square height and width
            baseIconView.heightAnchor.constraint(equalToConstant: Styling.baseIconLength),
            baseIconView.widthAnchor.constraint(equalToConstant: Styling.baseIconLength),
            
            // Set the stripe icon view's static square height and width
            stripeIconView.heightAnchor.constraint(equalToConstant: Styling.baseIconLength),
            stripeIconView.widthAnchor.constraint(equalToConstant: Styling.baseIconLength),

            // The stack view should have some padding for the shadow to show
            // and be aligned to the left. No trailing constraint needed.
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Styling.stackViewPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Styling.stackViewPadding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Styling.stackViewPadding),
        ])
    }
}
