//
//  InstructionalCameraScanningView.swift
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
final class InstructionalCameraScanningView: UIView {

    struct Styling {
        static let labelBottomPadding: CGFloat = 24
        static let labelMinHeightNumberOfLines: Int = 3
        static var labelFont: UIFont {
            IdentityUI.instructionsFont
        }
    }

    struct ViewModel {
        let scanningViewModel: CameraScanningView.ViewModel
        let instructionalText: String
    }

    // MARK: Views

    private lazy var labelMaxTopPaddingConstraint = NSLayoutConstraint()

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Styling.labelFont
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let scanningView = CameraScanningView()

    // MARK: Init

    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
        adjustLabelTopPadding()

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
        label.text = viewModel.instructionalText
        scanningView.configure(with: viewModel.scanningViewModel)
        accessibilityLabel = viewModel.instructionalText

        // Notify the accessibility VoiceOver that layout has changed
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    // MARK: UIView

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // NOTE: `traitCollectionDidChange` is called off the main thread when the app backgrounds
        DispatchQueue.main.async { [weak self] in
            self?.adjustLabelTopPadding()
        }
    }
}

// MARK: - Helpers

private extension InstructionalCameraScanningView {
    func installViews() {
        addSubview(label)
        addSubview(scanningView)
    }

    func installConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
        scanningView.translatesAutoresizingMaskIntoConstraints = false

        label.setContentHuggingPriority(.required, for: .vertical)

        /*
         The label should be bottom-aligned to the scanningView, leaving enough
         vertical space above the label to display up to
         `Styling.labelMinHeightNumberOfLines` lines of text.

         Constrain the bottom of the label >= the top of this view using a
         constant equivalent to the height of `labelMinHeightNumberOfLines` of
         text, taking the label's font into account.

         Constrain the top of the label to the top of this view with a lower
         priority constraint so the label will align to the top if its text
         exceeds `labelMinHeightNumberOfLines`.
         */
        let labelMinTopPaddingConstraint = label.topAnchor.constraint(equalTo: topAnchor)
        labelMinTopPaddingConstraint.priority = .defaultHigh

        // This constant is set in adjustLabelTopPadding()
        labelMaxTopPaddingConstraint = label.bottomAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 0)

        NSLayoutConstraint.activate([
            labelMinTopPaddingConstraint,
            labelMaxTopPaddingConstraint,
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),

            label.bottomAnchor.constraint(equalTo: scanningView.topAnchor, constant: -Styling.labelBottomPadding),

            scanningView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scanningView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scanningView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func adjustLabelTopPadding() {
        // Create some text that is the minimum number of lines of text and
        // compute its height based on the label's font
        let textWithMinLines = Array(repeating: "\n", count: Styling.labelMinHeightNumberOfLines-1).joined()

        labelMaxTopPaddingConstraint.constant = (textWithMinLines as NSString).size(withAttributes: [
            .font:  Styling.labelFont
        ]).height
    }
}
