//
//  FileUploadView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/4/22.
//

import Foundation
import UIKit

final class FileUploadView: UIView {

    struct Styling {
        static let labelHorizontalPadding: CGFloat = 16
        static let listHorizontalPadding: CGFloat = 12
        static let labelListVerticalSpacing: CGFloat = 24
    }

    struct ViewModel {
        let instructionText: String
        let listViewModel: ListView.ViewModel
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

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(with viewModel: ViewModel) {
        label.text = viewModel.instructionText
        listView.configure(with: viewModel.listViewModel)
    }
}

private extension FileUploadView {
    func installViews() {
        addSubview(label)
        addSubview(listView)
    }

    func installConstraints() {
        label.translatesAutoresizingMaskIntoConstraints = false
        listView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Styling.labelHorizontalPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Styling.labelHorizontalPadding),
            listView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Styling.listHorizontalPadding),
            listView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Styling.listHorizontalPadding),

            label.topAnchor.constraint(equalTo: topAnchor),
            listView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: Styling.labelListVerticalSpacing),
            listView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
