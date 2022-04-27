//
//  BottomAlignedLabel.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/26/22.
//

import Foundation
import UIKit

final class BottomAlignedLabel: UIView {

    struct ViewModel {
        let text: String
        let minNumberOfLines: Int
        let font: UIFont
        let textAlignment: NSTextAlignment
        let adjustsFontForContentSizeCategory: Bool

        init(
            text: String,
            minNumberOfLines: Int,
            font: UIFont,
            textAlignment: NSTextAlignment = .center,
            adjustsFontForContentSizeCategory: Bool = true
        ) {
            self.text = text
            self.minNumberOfLines = minNumberOfLines
            self.font = font
            self.textAlignment = textAlignment
            self.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory
        }

    }

    // MARK: - Properties

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    private var labelMaxTopPaddingConstraint = NSLayoutConstraint()

    private var minNumberOfLines: Int = 1

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        addSubview(label)
        installConstraints()
    }

    convenience init(from viewModel: ViewModel) {
        self.init()
        configure(from: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(from viewModel: ViewModel) {
        self.minNumberOfLines = viewModel.minNumberOfLines

        label.text = viewModel.text
        label.font = viewModel.font
        label.textAlignment = viewModel.textAlignment
        label.adjustsFontForContentSizeCategory = viewModel.adjustsFontForContentSizeCategory

        adjustLabelTopPadding()
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

private extension BottomAlignedLabel {
    func installConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
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
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }

    func adjustLabelTopPadding() {
        guard let font = label.font else { return }

        // In case `minNumberOfLines` is <=0, use a min of 1
        let minNumberOfLines = max(self.minNumberOfLines, 1)

        // Create some text that is the minimum number of lines of text and
        // compute its height based on the label's font
        let textWithMinLines = " " + Array(repeating: "\n", count: minNumberOfLines-1).joined()

        labelMaxTopPaddingConstraint.constant = (textWithMinLines as NSString).size(withAttributes: [
            .font: font
        ]).height
    }
}
