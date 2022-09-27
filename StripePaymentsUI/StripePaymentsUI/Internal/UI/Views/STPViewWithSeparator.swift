//
//  STPViewWithSeparator.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPViewWithSeparator: UIView {
    private var topSeparator = UIView()
    private var bottomSeparator = UIView()
    private var separatorHeightConstraint = NSLayoutConstraint()

    @objc public var topSeparatorHidden: Bool {
        get {
            return topSeparator.isHidden
        }
        set(topSeparatorHidden) {
            topSeparator.isHidden = topSeparatorHidden
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _addSeparators()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        _addSeparators()
    }

    func _addSeparators() {
        if #available(iOS 13.0, *) {
            topSeparator.backgroundColor = UIColor.opaqueSeparator
        } else {
            // Fallback on earlier versions
            topSeparator.backgroundColor = UIColor.lightGray
        }

        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topSeparator)

        separatorHeightConstraint = topSeparator.heightAnchor.constraint(
            equalToConstant: _currentPixelHeight())

        if #available(iOS 13.0, *) {
            bottomSeparator.backgroundColor = UIColor.opaqueSeparator
        } else {
            // Fallback on earlier versions
            bottomSeparator.backgroundColor = UIColor.lightGray
        }

        bottomSeparator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomSeparator)

        NSLayoutConstraint.activate(
            [
                topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
                topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
                topSeparator.topAnchor.constraint(equalTo: topAnchor),
                separatorHeightConstraint,
                bottomSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
                bottomSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
                bottomSeparator.bottomAnchor.constraint(equalTo: bottomAnchor),
                bottomSeparator.heightAnchor.constraint(
                    equalTo: topSeparator.heightAnchor, multiplier: 1.0),
            ])
    }

    /// :nodoc:
    @objc
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        separatorHeightConstraint.constant = _currentPixelHeight()
    }

    func _currentPixelHeight() -> CGFloat {
        let screen = window?.screen ?? UIScreen.main
        if screen.nativeScale > 0 {
            return 1.0 / screen.nativeScale
        } else {
            return 0.5
        }
    }
}
