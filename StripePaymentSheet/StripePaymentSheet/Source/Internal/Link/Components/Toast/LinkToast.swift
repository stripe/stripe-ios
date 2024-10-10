//
//  LinkToast.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// A view for displaying a brief message to the user.
/// For internal SDK use only
@objc(STP_Internal_LinkToast)
final class LinkToast: UIView {
    struct Constants {
        static let padding: CGFloat = 12
        /// Space between the icon and label.
        static let spacing: CGFloat = 8
        static let animationDuration: TimeInterval = 0.2
        static let animationTravelDistance: CGFloat = 40
        static let defaultDuration: TimeInterval = 2
    }

    enum ToastType {
        case success
    }

    let toastType: ToastType

    let text: String

    private let iconView = UIImageView()

    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .linkToastForeground
        label.font = LinkUI.font(forTextStyle: .detail, maximumPointSize: 20)
        return label
    }()
    #if !os(visionOS)
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    #endif

    /// Creates a new toast.
    /// - Parameters:
    ///   - type: Toast type.
    ///   - text: Text to show.
    init(type: ToastType, text: String) {
        self.toastType = type
        self.text = text
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .linkToastBackground
        directionalLayoutMargins = .insets(amount: Constants.padding)

        insetsLayoutMarginsFromSafeArea = false

        label.text = text
        iconView.image = toastType.icon
        iconView.tintColor = toastType.iconColor

        let stackView = UIStackView(arrangedSubviews: [iconView, label])
        stackView.spacing = Constants.spacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

}

// MARK: - Show/Hide

extension LinkToast {

    /// Show the toast from the given view as context.
    /// - Parameters:
    ///   - view: View to show the toast from.
    ///   - duration: How long to show the toast for.
    func show(from view: UIView, duration: TimeInterval = Constants.defaultDuration) {
        let presentingView = view.window ?? view

        translatesAutoresizingMaskIntoConstraints = false
        presentingView.addSubview(self)

        NSLayoutConstraint.activate([
            // Horizontally center
            centerXAnchor.constraint(equalTo: presentingView.safeAreaLayoutGuide.centerXAnchor),

            // Pin edges
            topAnchor.constraint(equalTo: presentingView.safeAreaLayoutGuide.topAnchor),
            leadingAnchor.constraint(greaterThanOrEqualTo: presentingView.layoutMarginsGuide.leadingAnchor),
            trailingAnchor.constraint(lessThanOrEqualTo: presentingView.layoutMarginsGuide.trailingAnchor),
        ])

        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: -Constants.animationTravelDistance)

        UIView.animate(
            withDuration: Constants.animationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            self.alpha = 1
            self.transform = .identity
        }

        UIAccessibility.post(notification: .announcement, argument: text)
        #if !os(visionOS)
        generateHapticFeedback()
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.hide()
        }
    }

    /// Hides toast.
    ///
    /// You normally don't need to call this, as the toast will hide on its own after an specific duration.
    func hide() {
        guard superview != nil else {
            return
        }

        UIView.animate(
            withDuration: Constants.animationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -Constants.animationTravelDistance)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

#if !os(visionOS)
    private func generateHapticFeedback() {
        switch toastType {
        case .success:
            feedbackGenerator.notificationOccurred(.success)
        }
    }
#endif

}

extension LinkToast.ToastType {

    var icon: UIImage {
        switch self {
        case .success:
            return Image.icon_link_success.makeImage(template: true)
        }
    }

    var iconColor: UIColor {
        switch self {
        case .success:
            return .linkBrand
        }
    }

}
