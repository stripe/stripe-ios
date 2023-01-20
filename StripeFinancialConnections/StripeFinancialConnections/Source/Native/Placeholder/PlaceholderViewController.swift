//
//  ConsentViewController.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

@_spi(STP) import StripeUICore
import UIKit

class PlaceholderViewController: UIViewController {

    // MARK: - UI Elements

    private lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = paneTitle
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(actionTitle, for: .normal)
        button.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties

    private let paneTitle: String
    private let actionTitle: String
    private let actionBlock: () -> Void

    // MARK: - Init

    init(paneTitle: String, actionTitle: String, actionBlock: @escaping () -> Void) {
        self.paneTitle = paneTitle
        self.actionTitle = actionTitle
        self.actionBlock = actionBlock
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        installViews()
        installConstraints()
    }
}

// MARK: - Helpers
fileprivate extension PlaceholderViewController {

    func installViews() {
        view.backgroundColor = .systemBackground
        view.addSubview(label)
        view.addSubview(actionButton)
    }

    func installConstraints() {
        NSLayoutConstraint.activate([
            // Center temporary label
            label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),

            // Pin button to the bottom of safe area
            actionButton.leftAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leftAnchor,
                constant: Styling.actionButtonSpacing
            ),
            actionButton.rightAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.rightAnchor,
                constant: -Styling.actionButtonSpacing
            ),
            actionButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Styling.actionButtonSpacing
            ),
        ])
    }

    @objc
    func didTapActionButton() {
        actionBlock()
    }
}

// MARK: - Styling

fileprivate extension PlaceholderViewController {
    enum Styling {
        static let actionButtonSpacing: CGFloat = 20
    }
}
