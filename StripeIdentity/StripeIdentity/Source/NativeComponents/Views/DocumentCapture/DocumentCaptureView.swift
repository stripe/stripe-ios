//
//  DocumentCaptureView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

/// Displays either an instructional camera scanning view or an error message
final class DocumentCaptureView: UIView {

    enum ViewModel {
        case scan(InstructionalDocumentScanningView.ViewModel)
        case error(ErrorView.ViewModel)
    }

    private let scanningView = InstructionalDocumentScanningView()

    private let errorView = ErrorView()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        installViews()
    }

    convenience init(
        from viewModel: ViewModel
    ) {
        self.init()
        configure(with: viewModel)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel) {
        switch viewModel {
        case .scan(let scanningViewModel):
            scanningView.configure(with: scanningViewModel)
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

extension DocumentCaptureView {
    fileprivate func installViews() {
        addAndPinSubview(stackView)
        stackView.addArrangedSubview(scanningView)
        stackView.addArrangedSubview(errorView)
    }
}
