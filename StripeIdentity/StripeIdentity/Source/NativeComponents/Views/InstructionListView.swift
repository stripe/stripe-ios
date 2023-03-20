//
//  InstructionListView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/4/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class InstructionListView: UIView {

    struct Styling {
        static let labelHorizontalPadding: CGFloat = 16
        static let listHorizontalPadding: CGFloat = 12
        static let labelListVerticalSpacing: CGFloat = 24

        static var labelInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: labelHorizontalPadding - listHorizontalPadding,
            bottom: 0,
            trailing: labelHorizontalPadding - listHorizontalPadding
        )

        static var vStackInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: listHorizontalPadding,
            bottom: 0,
            trailing: listHorizontalPadding
        )
    }

    struct ViewModel {
        let instructionText: String?
        let listViewModel: ListView.ViewModel?
    }

    // MARK: - Properties

    let listView = ListView()

    private let label: UILabel = {
        let label = UILabel()
        label.font = IdentityUI.instructionsFont
        label.accessibilityTraits = [.staticText]
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let labelInsetView = UIView()

    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = Styling.labelListVerticalSpacing
        return stackView
    }()

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        installViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(with viewModel: ViewModel) {
        labelInsetView.isHidden = (viewModel.instructionText == nil)
        label.text = viewModel.instructionText

        if let listViewModel = viewModel.listViewModel {
            listView.configure(with: listViewModel)
            listView.isHidden = false
        } else {
            listView.isHidden = true
        }
    }
}

private extension InstructionListView {
    func installViews() {
        labelInsetView.addAndPinSubview(label, insets: Styling.labelInsets)
        vStack.addArrangedSubview(labelInsetView)
        vStack.addArrangedSubview(listView)
        addAndPinSubview(vStack, insets: Styling.vStackInsets)
    }
}
