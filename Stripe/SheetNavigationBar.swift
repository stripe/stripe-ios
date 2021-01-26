//
//  SheetNavigationBar.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 10/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol SheetNavigationBarDelegate: AnyObject {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar)
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar)
}

class SheetNavigationBar: UIView {
    static let height: CGFloat = 48
    weak var delegate: SheetNavigationBarDelegate?
    fileprivate let closeButton = NavBarCirclularButton(style: .close)
    fileprivate let backButton = NavBarCirclularButton(style: .back)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = CompatibleColor.systemBackground.withAlphaComponent(0.9)
        [closeButton, backButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -PaymentSheetUI.defaultPadding),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: PaymentSheetUI.defaultPadding),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)

        setStyle(.close)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Self.height)
    }

    @objc
    private func didTapCloseButton() {
        delegate?.sheetNavigationBarDidClose(self)
    }

    @objc
    private func didTapBackButton() {
        delegate?.sheetNavigationBarDidBack(self)
    }

    // MARK: -
    enum Style {
        case close
        case back
    }

    func setStyle(_ style: Style) {
        switch style {
        case .back:
            closeButton.isHidden = true
            backButton.isHidden = false
        case .close:
            closeButton.isHidden = false
            backButton.isHidden = true
        }
    }

    func setShadowHidden(_ isHidden: Bool) {
        layer.shadowPath = CGPath(rect: bounds, transform: nil)
        layer.shadowOpacity = isHidden ? 0 : 0.1
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}

// MARK: -

fileprivate class NavBarCirclularButton: UIControl {
    private let radius: CGFloat = 10
    private let shadowOpacity: Float = 0.5
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = CompatibleColor.secondaryLabel
        return imageView
    }()
    enum Style {
        case back
        case close
    }

    required init(style: Style) {
        super.init(frame: .zero)

        backgroundColor = UIColor.dynamic(light: CompatibleColor.systemBackground, dark: CompatibleColor.systemGray2)
        layer.cornerRadius = radius
        layer.masksToBounds = false
        isAccessibilityElement = true
        accessibilityTraits = [.button]

        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 1.5
        layer.shadowColor = CompatibleColor.systemGray2.cgColor
        layer.shadowOpacity = shadowOpacity
        let path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: radius,
                                startAngle: 0,
                                endAngle: CGFloat.pi * 2,
                                clockwise: true)
        layer.shadowPath = path.cgPath

        addSubview(imageView)
        switch style {
        case .back:
            imageView.image = Icon.chevronLeft.makeImage()
            accessibilityLabel = STPLocalizedString("Back", "Text for back button")
        case .close:
            imageView.image = Icon.x.makeImage()
            accessibilityLabel = STPLocalizedString("Close", "Text for close button")
        }
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -0.5),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        updateShadow()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let newArea = bounds.insetBy(dx: -(PaymentSheetUI.minimumTapSize.width - bounds.width) / 2,
                                     dy: -(PaymentSheetUI.minimumTapSize.height - bounds.height) / 2)
        return newArea.contains(point)
    }

    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            backgroundColor = CompatibleColor.systemGray2
        case .shouldDisableUserInteraction:
            backgroundColor = CompatibleColor.systemIndigo
        default:
            break
        }
    }

    func updateShadow() {
        // Turn off shadows in dark mode
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                layer.shadowOpacity = 0
            } else {
                layer.shadowOpacity = shadowOpacity
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateShadow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: radius * 2, height: radius * 2)
    }
}
