//
//  WebViewErrorScreen.swift
//  StripeConnect
//
//  Created by Chris Mays on 2/25/25.
//

import UIKit

@available(iOS 15, *)
class WebViewErrorScreen: UIView {

    let titleFontSize = 24.0
    let subtitleFontSize = 16.0

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init(title: String, subtitle: String, appearance: EmbeddedComponentManager.Appearance) {
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.titleLabel.text = title
        self.subtitleLabel.text = subtitle
        updateAppearance(appearance)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func updateAppearance(_ appearance: EmbeddedComponentManager.Appearance) {
        self.titleLabel.font = appearance.typography.font?.withSize(titleFontSize) ?? UIFont.systemFont(ofSize: titleFontSize)
        self.subtitleLabel.font = appearance.typography.font?.withSize(subtitleFontSize) ?? UIFont.systemFont(ofSize: subtitleFontSize)
    }

    private func setupView() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20),
        ])
    }
}
