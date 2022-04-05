//
//  ErrorView.swift
//  StripeIdentity
//
//  Created by Jaime Park on 2/10/22.
//

import UIKit
@_spi(STP) import StripeUICore

class ErrorView: UIView {
    struct Styling {
        static let errorTitleLabelSpacing: CGFloat = 12
        static let contentInset: NSDirectionalEdgeInsets = .init(top: 132, leading: 16, bottom: 0, trailing: 16)
        static let warningIconImageSpacing: CGFloat = 27
    }

    struct ViewModel {
        let titleText: String
        let bodyText: String
    }

    private let errorTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = IdentityUI.titleFont
        label.accessibilityTraits = [.header]
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let errorBodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = IdentityUI.instructionsFont
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private let warningIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = Image.iconWarning92.makeImage(template: true)
        imageView.tintColor = IdentityUI.iconColor
        return imageView
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
        errorTitleLabel.text = viewModel.titleText
        errorBodyLabel.text = viewModel.bodyText
    }
}

private extension ErrorView {
    func installViews() {
        addAndPinSubview(stackView, insets: Styling.contentInset)
        stackView.addArrangedSubview(warningIconImageView)
        stackView.addArrangedSubview(errorTitleLabel)
        stackView.addArrangedSubview(errorBodyLabel)

        // Custom spacings that match designs
        stackView.setCustomSpacing(Styling.warningIconImageSpacing, after: warningIconImageView)
        stackView.setCustomSpacing(Styling.errorTitleLabelSpacing, after: errorTitleLabel)
    }

    func installConstraints() {
        warningIconImageView.setContentHuggingPriority(.required, for: .vertical)
        warningIconImageView.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
