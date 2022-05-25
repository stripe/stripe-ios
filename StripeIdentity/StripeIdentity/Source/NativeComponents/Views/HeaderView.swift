//
//  HeaderView.swift
//  StripeIdentity
//
//  Created by Jaime Park on 1/25/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// Displays either a header with some icons and title or a header with just the title
class HeaderView: UIView {
    typealias IconViewModel = HeaderIconView.ViewModel

    struct Styling {
        static let leadingTrailingConstraint: CGFloat = 16

        static let stackViewSpacing: CGFloat = 32

        static func bottomConstraint(headerType: ViewModel.HeaderType) -> CGFloat {
            switch headerType {
            case .banner:
                return 26
            case .plain:
                return 0
            }
        }

        static func topConstraint(headerType: ViewModel.HeaderType) -> CGFloat {
            switch headerType {
            case .banner:
                return 42
            case .plain:
                return 57
            }
        }

        static func textAlignment(headerType: ViewModel.HeaderType) -> NSTextAlignment {
            switch headerType {
            case .banner:
                return .left
            case .plain:
                return .center
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

    private lazy var topAnchorConstraint: NSLayoutConstraint = stackView.topAnchor.constraint(equalTo: topAnchor)
    private lazy var bottomAnchorConstraint: NSLayoutConstraint = stackView.bottomAnchor.constraint(equalTo: bottomAnchor)

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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension HeaderView {
    // Set the all the header dependent styling
    func configureStyle(with viewModel: ViewModel) {
        backgroundColor = viewModel.backgroundColor

        titleLabel.text = viewModel.titleText
        titleLabel.textAlignment = Styling.textAlignment(headerType: viewModel.headerType)
    }

    // Reconfigure subviews and reset constraint constants
    func installHeaderView(with viewModel: ViewModel) {
        // Stack view combinations
        // Banner header: icon + title
        // Plain header: title
        if case .banner(.some(let viewModel)) = viewModel.headerType {
            iconView.configure(with: viewModel)
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }

        topAnchorConstraint.constant = Styling.topConstraint(headerType: viewModel.headerType)
        bottomAnchorConstraint.constant = -Styling.bottomConstraint(headerType: viewModel.headerType)
    }

    // Call on init to set stack view in view
    func installStackView() {
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(titleLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        NSLayoutConstraint.activate([
            topAnchorConstraint,
            bottomAnchorConstraint,
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Styling.leadingTrailingConstraint),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Styling.leadingTrailingConstraint),
        ])
    }
}
