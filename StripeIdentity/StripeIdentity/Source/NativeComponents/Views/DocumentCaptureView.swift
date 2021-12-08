//
//  DocumentCaptureView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 12/1/21.
//

import UIKit
@_spi(STP) import StripeUICore

/// Displays either an instructional camera scanning view or an error message
final class DocumentCaptureView: UIView {

    enum ViewModel {
        case scan(InstructionalCameraScanningView.ViewModel)
        case error(String)
    }

    private let scanningView = InstructionalCameraScanningView()

    // TODO(mludowise|IDPROD-2747): Use error view instead of label
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        installViews()
    }

    convenience init(from viewModel: ViewModel) {
        self.init()
        configure(with: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel) {
        switch viewModel {
        case .scan(let scanningViewModel):
            scanningView.configure(with: scanningViewModel)
            scanningView.isHidden = false
            errorLabel.isHidden = true
        case .error(let message):
            errorLabel.text = message
            scanningView.isHidden = true
            errorLabel.isHidden = false
        }
    }
}

// MARK: - Private Helpers

private extension DocumentCaptureView {
    func installViews() {
        addAndPinSubview(stackView)
        stackView.addArrangedSubview(scanningView)
        stackView.addArrangedSubview(errorLabel)
    }
}
