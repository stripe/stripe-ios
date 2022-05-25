//
//  LoadingViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/28/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// Simple view controller with a spinner
final class LoadingViewController: UIViewController {
    struct Styling {
        static let inset = NSDirectionalEdgeInsets(top: 32, leading: 16, bottom: 0, trailing: 16)
    }

    private let spinner: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        return activityIndicator
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.text = String.Localized.loading
        label.font = IdentityUI.titleFont
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = IdentityUI.containerColor
        installViews()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        spinner.startAnimating()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        spinner.stopAnimating()
    }
}

private extension LoadingViewController {
    func installViews() {
        view.addSubview(spinner)
        view.addSubview(loadingLabel)
    }

    func installConstraints() {
        [spinner, loadingLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            loadingLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            loadingLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            loadingLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Styling.inset.leading),
            loadingLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Styling.inset.trailing),


            spinner.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            spinner.bottomAnchor.constraint(equalTo: loadingLabel.topAnchor, constant: -Styling.inset.top),
        ])
    }
}
