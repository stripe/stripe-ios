//
//  HeaderIconView.swift
//  StripeIdentity
//
//  Created by Jaime Park on 2/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// This view will contain the icons that will be above a banner type header view.
// Here are the two types of icon views:
//
// Brand icon + Stripe icon
// +-----------------------+
// |     +---+   +---+     |
// |     | B | + | S |     |
// |     +---+   +---+     |
// +-----------------------+
//
// A singular icon (i.e. error icon)
// +------------------------+
// |         +---+          |
// |         | B |          |
// |         +---+          |
// +------------------------+
class HeaderIconView: UIView {
    struct Styling {
        static let largeBaseIconLength: CGFloat = 64
        static let largeCornerRadius: CGFloat = 16

        static let baseIconLength: CGFloat = 32
        static let cornerRadius: CGFloat = 8

        static let shadowConfig = ShadowConfiguration(
            shadowColor: .black,
            shadowOffset: CGSize(width: 0, height: 2),
            shadowOpacity: 0.12,
            shadowRadius: 1.0
        )

        static let stackViewPadding: CGFloat = 2
        static let stackViewSpacing: CGFloat = 8
    }

    struct ViewModel {
        enum IconType {
            case brand
            case plain
        }

        let iconType: IconType
        let iconImage: UIImage
        let iconImageContentMode: UIView.ContentMode
        let iconTintColor: UIColor?
        let shouldIconBackgroundMatchTintColor: Bool
        var useLargeIcon: Bool = false

        func baseIconViewModel(useLargeIcon: Bool, tintColor: UIColor?) -> ShadowedCorneredImageView.ViewModel {
            return .init(
                image: iconImage,
                imageContentMode: iconImageContentMode,
                imageTintColor: iconTintColor,
                backgroundColor: shouldIconBackgroundMatchTintColor ? tintColor : nil,
                cornerRadius: useLargeIcon ? Styling.largeCornerRadius : Styling.cornerRadius,
                shadowConfiguration: Styling.shadowConfig
            )
        }

        init(
            iconType: IconType,
            iconImage: UIImage,
            iconImageContentMode: UIView.ContentMode,
            iconTintColor: UIColor? = nil,
            shouldIconBackgroundMatchTintColor: Bool = false,
            useLargeIcon: Bool = false
        ) {
            self.iconType = iconType
            self.iconImage = iconImage
            self.iconImageContentMode = iconImageContentMode
            self.iconTintColor = iconTintColor
            self.shouldIconBackgroundMatchTintColor = shouldIconBackgroundMatchTintColor
            self.useLargeIcon = useLargeIcon
        }
    }

    // MARK: Views
    private let baseIconView: ShadowedCorneredImageView = ShadowedCorneredImageView()

    private let ellipsisIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.image = Image.iconEllipsis.makeImage(template: false)
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
                imageContentMode: .scaleAspectFill,
                imageTintColor: nil,
                backgroundColor: nil,
                cornerRadius: Styling.cornerRadius,
                shadowConfiguration: Styling.shadowConfig
            )
        )

        return view
    }()

    // MARK: - Properties

    // Cache view model for when tint color updates
    private var viewModel: ViewModel?

    // MARK: - Inits
    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel) {
        // Only cache the view model if necessary for updating background color
        self.viewModel = viewModel.shouldIconBackgroundMatchTintColor ? viewModel : nil

        baseIconView.configure(viewModel: viewModel.baseIconViewModel(useLargeIcon: viewModel.useLargeIcon, tintColor: tintColor))

        switch viewModel.iconType {
        case .brand:
            ellipsisIconView.isHidden = false
            stripeIconView.isHidden = false
        case .plain:
            ellipsisIconView.isHidden = true
            stripeIconView.isHidden = true
        }

        updateIconSize(useLargeIcon: viewModel.useLargeIcon)
    }

    // MARK: - UIView

    override func tintColorDidChange() {
        super.tintColorDidChange()

        guard let viewModel = viewModel else {
            return
        }

        baseIconView.configure(viewModel: viewModel.baseIconViewModel(useLargeIcon: viewModel.useLargeIcon, tintColor: tintColor))
    }
}

extension HeaderIconView {
    fileprivate func installViews() {
        stackView.addArrangedSubview(baseIconView)
        stackView.addArrangedSubview(ellipsisIconView)
        stackView.addArrangedSubview(stripeIconView)
        addSubview(stackView)
    }

    fileprivate func installConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // The stack view should have some padding for the shadow to show
            // and be aligned to the center.
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Styling.stackViewPadding),
            stackView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -Styling.stackViewPadding
            ),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    fileprivate func updateIconSize(useLargeIcon: Bool) {
        let iconLength = useLargeIcon ? Styling.largeBaseIconLength : Styling.baseIconLength
        NSLayoutConstraint.activate([
            // Set the base icon view's static square height and width
            baseIconView.heightAnchor.constraint(equalToConstant: iconLength),
            baseIconView.widthAnchor.constraint(equalToConstant: iconLength),

            // Set the stripe icon view's static square height and width
            stripeIconView.heightAnchor.constraint(equalToConstant: iconLength),
            stripeIconView.widthAnchor.constraint(equalToConstant: iconLength),
        ])
    }
}
