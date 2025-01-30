//
//  LoadingView.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/3/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class LoadingView: UIView {

    private let appearance: FinancialConnectionsAppearance?

    // MARK: - Subview Properties

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = STPLocalizedString(
            "Failed to connect",
            "Error message that displays when we're unable to connect to the server."
        )
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = Styling.errorLabelFont
        label.textColor = FinancialConnectionsAppearance.Colors.textDefault
        return label
    }()

    private(set) lazy var tryAgainButton: StripeUICore.Button = {

        let button = StripeUICore.Button(
            configuration: .primary(),
            title: String.Localized.tryAgain
        )
        return button
    }()

    internal let errorView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = Styling.errorViewSpacing
        return stackView
    }()

    private lazy var spinnerView = {
        SpinnerView(appearance: appearance, shouldStartAnimating: false)
    }()

    // MARK: - Init

    init(frame: CGRect, appearance: FinancialConnectionsAppearance?) {
        self.appearance = appearance
        super.init(frame: frame)

        errorView.addArrangedSubview(errorLabel)
        errorView.addArrangedSubview(tryAgainButton)
        addSubview(errorView)

        // Add constraints
        errorView.translatesAutoresizingMaskIntoConstraints = false

        tryAgainButton.setContentHuggingPriority(.required, for: .vertical)
        tryAgainButton.setContentCompressionResistancePriority(.required, for: .vertical)
        errorLabel.setContentHuggingPriority(.required, for: .vertical)
        errorLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            // Pin error view to top
            errorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        addAndPinSubview(spinnerView)
        showLoading(false)
    }

    func showLoading(_ showLoading: Bool) {
        spinnerView.isHidden = !showLoading
        if showLoading {
            spinnerView.startAnimating()
        } else {
            spinnerView.stopAnimating()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Styling

private extension LoadingView {
    enum Styling {
        static let errorViewSpacing: CGFloat = 16
        static var errorLabelFont: UIFont {
            UIFont.preferredFont(forTextStyle: .body, weight: .medium)
        }
    }
}
