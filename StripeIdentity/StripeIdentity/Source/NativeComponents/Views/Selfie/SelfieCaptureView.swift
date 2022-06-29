//
//  SelfieCaptureView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/27/22.
//

import UIKit
@_spi(STP) import StripeUICore

/// Displays either an instructional camera scanning view or an error message
final class SelfieCaptureView: UIView {

    struct Styling {
        // Used for errorView and vertical insets of scanningView
        static let contentInsets = IdentityFlowView.Style.defaultContentViewInsets
    }

    enum ViewModel {
        case scan(SelfieScanningView.ViewModel)
        case error(ErrorView.ViewModel)
    }

    private let scanningView = SelfieScanningView()

    private let errorView = ErrorView()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel, analyticsClient: IdentityAnalyticsClient?) {
        switch viewModel {
        case .scan(let scanningViewModel):
            scanningView.configure(
                with: scanningViewModel,
                analyticsClient: analyticsClient
            )
            scanningView.isHidden = false
            errorView.isHidden = true
        case .error(let errorViewModel):
            errorView.configure(with: errorViewModel)
            scanningView.isHidden = true
            errorView.isHidden = false
        }
    }
}

// MARK: - Private Helpers

private extension SelfieCaptureView {
    func installViews() {
        // Add top/bottom content insets to stackView
        addAndPinSubview(stackView, insets: .init(
            top: Styling.contentInsets.top,
            leading: 0,
            bottom: Styling.contentInsets.bottom,
            trailing: 0
        ))
        stackView.addArrangedSubview(scanningView)
        stackView.addArrangedSubview(errorView)
    }

    func installConstraints() {
        // Add the horizontal contentInset to errorView (scanningView has horizontal insets built in already)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(
                equalTo: errorView.widthAnchor,
                constant: Styling.contentInsets.leading + Styling.contentInsets.trailing
            ),
            scanningView.widthAnchor.constraint(equalTo: widthAnchor),
        ])
    }
}
