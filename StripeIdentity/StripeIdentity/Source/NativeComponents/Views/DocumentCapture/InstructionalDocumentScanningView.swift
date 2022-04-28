//
//  InstructionalDocumentScanningView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/8/21.
//

import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCameraCore

/**
 A view that displays instructions to the user underneath a live camera feed.
 The view can be configured such that it can either display a live camera feed or
 a static image in place of the camera feed.
 */
final class InstructionalDocumentScanningView: UIView {

    struct Styling {
        static let labelBottomPadding = IdentityUI.scanningViewLabelBottomPadding
        static let labelMinHeightNumberOfLines = IdentityUI.scanningViewLabelMinHeightNumberOfLines
        static var labelFont: UIFont {
            IdentityUI.instructionsFont
        }
    }

    struct ViewModel {
        let scanningViewModel: DocumentScanningView.ViewModel
        let instructionalText: String

        var labelViewModel: BottomAlignedLabel.ViewModel {
            return .init(
                text: instructionalText,
                minNumberOfLines: Styling.labelMinHeightNumberOfLines,
                font: Styling.labelFont
            )
        }
    }

    // MARK: Views

    private let label = BottomAlignedLabel()

    private let scanningView = DocumentScanningView()

    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = Styling.labelBottomPadding
        return stackView
    }()

    // MARK: Init

    init() {
        super.init(frame: .zero)
        installViews()

        isAccessibilityElement = true
    }

    convenience init(from viewModel: ViewModel) {
        self.init()
        configure(with: viewModel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel) {
        label.configure(from: viewModel.labelViewModel)
        scanningView.configure(with: viewModel.scanningViewModel)
        accessibilityLabel = viewModel.instructionalText

        // Notify the accessibility VoiceOver that layout has changed
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
}

// MARK: - Helpers

private extension InstructionalDocumentScanningView {
    func installViews() {
        addAndPinSubview(vStack)
        vStack.addArrangedSubview(label)
        vStack.addArrangedSubview(scanningView)
    }
}
