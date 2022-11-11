//
//  HeaderView.swift
//  StripeIdentity
//
//  Created by Jaime Park on 1/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// Displays either a header with some icons and title or a header with just the title
class HeaderView: UIView {
    typealias IconViewModel = HeaderIconView.ViewModel

    struct Styling {
        static let leadingTrailingConstraint: CGFloat = 16

        static let stackViewSpacing: CGFloat = 16

        static func topConstraint(headerType: ViewModel.HeaderType) -> CGFloat {
            switch headerType {
            case .banner:
                return 16
            case .plain:
                return 57
            }
        }
    }

    struct ViewModel {
        enum HeaderType {
            /// Only banner headers have an icon view
            case banner(iconViewModel: IconViewModel?)
            case plain
        }

        // Background color is configurable since the nav bar and header color has to match
        let backgroundColor: UIColor
        let headerType: HeaderType
        let titleText: String
    }

    private let iconView = HeaderIconView()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Styling.stackViewSpacing
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.accessibilityTraits = [.header]
        label.adjustsFontForContentSizeCategory = true
        label.font = IdentityUI.titleFont
        return label
    }()

    private lazy var topAnchorConstraint: NSLayoutConstraint = stackView.topAnchor.constraint(
        equalTo: topAnchor
    )
    private lazy var bottomAnchorConstraint: NSLayoutConstraint = stackView.bottomAnchor.constraint(
        equalTo: bottomAnchor
    )

    // MARK: Configure
    func configure(with viewModel: ViewModel) {
        // Install views and set constraints
        configureStyle(with: viewModel)
        installHeaderView(with: viewModel)
    }

    // MARK: - Inits
    init() {
        super.init(frame: .zero)
        installStackView()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HeaderView {
    // Set the all the header dependent styling
    fileprivate func configureStyle(with viewModel: ViewModel) {
        backgroundColor = viewModel.backgroundColor

        titleLabel.text = viewModel.titleText
        titleLabel.textAlignment = .center
    }

    // Reconfigure subviews and reset constraint constants
    fileprivate func installHeaderView(with viewModel: ViewModel) {
        // Stack view combinations
        // Banner header: icon + title
        // Plain header: title
        if case .banner(.some(let viewModel)) = viewModel.headerType {
            iconView.configure(with: viewModel)
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }

        topAnchorConstraint.constant = 16
    }

    // Call on init to set stack view in view
    fileprivate func installStackView() {
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(titleLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        NSLayoutConstraint.activate([
            topAnchorConstraint,
            bottomAnchorConstraint,
            stackView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: Styling.leadingTrailingConstraint
            ),
            stackView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -Styling.leadingTrailingConstraint
            ),
        ])
    }
}
