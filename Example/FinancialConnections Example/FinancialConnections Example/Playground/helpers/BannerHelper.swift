//
//  BannerUtility.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 10/2/23.
//

import UIKit

final class BannerHelper {

    static let shared = BannerHelper()

    private var windows: [UIWindow] = []

    private init() {}

    func showBanner(with message: String, for duration: TimeInterval) {
        let newWindow = UIWindow(frame: UIScreen.main.bounds)
        newWindow.windowLevel = UIWindow.Level.alert + 1
        newWindow.isHidden = false
        newWindow.backgroundColor = .clear
        // Allow touches to pass through
        newWindow.isUserInteractionEnabled = false
        windows.append(newWindow)

        let bannerView = BannerView()
        bannerView.display(
            message: message,
            for: duration,
            on: newWindow
        ) { [weak newWindow, weak bannerView] in
            bannerView?.removeFromSuperview()
            newWindow?.removeFromSuperview()
        }
    }
}

private class BannerView: UIView {

    private let messageLabel = UILabel()
    private var hideTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black.withAlphaComponent(0.8)

        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func display(
        message: String,
        for duration: TimeInterval,
        on window: UIWindow,
        completionHandler: @escaping () -> Void
    ) {
        messageLabel.text = message

        // add to window
        if superview == nil {
            window.addSubview(self)
            translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                leadingAnchor.constraint(equalTo: window.leadingAnchor),
                trailingAnchor.constraint(equalTo: window.trailingAnchor),
                topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor),
                heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            ])
        }

        // present
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }

        // hide (after timer completes)
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(
            withTimeInterval: duration,
            repeats: false
        ) { [weak self] _ in
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self?.alpha = 0.0
                },
                completion: { _ in
                    completionHandler()
                }
            )
        }
    }
}
