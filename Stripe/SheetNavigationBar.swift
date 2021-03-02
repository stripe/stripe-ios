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
    fileprivate let closeButton = CircularButton(style: .close)
    fileprivate let backButton = CircularButton(style: .back)
    let additionalButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(CompatibleColor.secondaryLabel, for: .normal)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        button.titleLabel?.font = fontMetrics.scaledFont(
            for: UIFont.systemFont(ofSize: 13, weight: .semibold))
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = CompatibleColor.systemBackground.withAlphaComponent(0.9)
        [closeButton, backButton, additionalButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: PaymentSheetUI.defaultPadding),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            backButton.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: PaymentSheetUI.defaultPadding),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            additionalButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.defaultPadding),
            additionalButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)

        setStyle(.close(showAdditionalButton: false))
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
        case close(showAdditionalButton: Bool)
        case back
    }

    func setStyle(_ style: Style) {
        switch style {
        case .back:
            closeButton.isHidden = true
            additionalButton.isHidden = true
            backButton.isHidden = false
            bringSubviewToFront(backButton)
        case .close(let showAdditionalButton):
            closeButton.isHidden = false
            additionalButton.isHidden = !showAdditionalButton
            if showAdditionalButton {
                bringSubviewToFront(additionalButton)
            }
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
