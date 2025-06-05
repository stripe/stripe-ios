//
//  StackViewWithSeparator.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 9/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// For internal SDK use only
@objc(STP_Internal_StackViewWithSeparator)
@_spi(STP) public class StackViewWithSeparator: UIStackView {

    public static let borderlessInset: CGFloat = 10

    public enum SeparatoryStyle {
        case full
        case partial
    }

    public var separatorStyle: SeparatoryStyle = .full {
        didSet {
            for view in arrangedSubviews {
                if let substackView = view as? StackViewWithSeparator {
                    substackView.separatorStyle = separatorStyle
                }
            }
        }
    }

    public var separatorColor: UIColor = .clear {
        didSet {
            separatorLayer.strokeColor = separatorColor.cgColor
            backgroundView.layer.borderColor = separatorColor.cgColor
        }
    }

    /// Commonly referred to as `borderWidth`
    public override var spacing: CGFloat {
        didSet {
            backgroundView.layer.borderWidth = spacing
            separatorLayer.lineWidth = spacing
            layoutMargins = UIEdgeInsets(
                top: spacing, left: spacing, bottom: spacing, right: spacing)
        }
    }

    public var drawBorder: Bool = false {
        didSet {
            isLayoutMarginsRelativeArrangement = drawBorder
            if drawBorder {
                addSubview(backgroundView)
                sendSubviewToBack(backgroundView)
            } else {
                backgroundView.removeFromSuperview()
            }
        }
    }

    public var borderCornerRadius: CGFloat {
        get {
            return backgroundView.layer.cornerRadius
        }
        set {
            backgroundView.layer.cornerRadius = newValue
        }
    }

    public var borderColor: UIColor = .systemGray3 {
        didSet {
            backgroundView.layer.borderColor = borderColor.cgColor
        }
    }

    @objc
    override public var isUserInteractionEnabled: Bool {
        didSet {
            if isUserInteractionEnabled {
                backgroundView.backgroundColor = customBackgroundColor
            } else {
                backgroundView.backgroundColor = customBackgroundDisabledColor
            }
        }
    }

    public var hideShadow: Bool = false {
        didSet {
            if hideShadow {
                backgroundView.layer.shadowOffset = .zero
                backgroundView.layer.shadowColor = UIColor.clear.cgColor
                backgroundView.layer.shadowOpacity = 0
                backgroundView.layer.shadowRadius = 0
                backgroundView.layer.shadowOpacity = 0
            } else {
                configureDefaultShadow()
            }
        }
    }

    public var customBackgroundColor: UIColor? = InputFormColors.backgroundColor {
        didSet {
            if isUserInteractionEnabled {
                backgroundView.backgroundColor = customBackgroundColor
            }
        }
    }

    public var customBackgroundDisabledColor: UIColor? = InputFormColors.disabledBackgroundColor {
        didSet {
            if isUserInteractionEnabled {
                backgroundView.backgroundColor = customBackgroundColor
            }
        }
    }

    private let separatorLayer = CAShapeLayer()
    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = InputFormColors.backgroundColor
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // copied from configureDefaultShadow to avoid recursion on init
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 4
        return view
    }()

    func configureDefaultShadow() {
        backgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        backgroundView.layer.shadowColor = UIColor.black.cgColor
        backgroundView.layer.shadowOpacity = 0.05
        backgroundView.layer.shadowRadius = 4
    }

    override public func layoutSubviews() {
        if backgroundView.superview == self {
            sendSubviewToBack(backgroundView)
        }
        super.layoutSubviews()
        if separatorLayer.superlayer == nil {
            layer.addSublayer(separatorLayer)
        }
        separatorLayer.strokeColor = separatorColor.cgColor

        let path = UIBezierPath()
        path.lineWidth = spacing

        if spacing > 0 {
            // inter-view separators
            let nonHiddenArrangedSubviews = arrangedSubviews.filter({ !$0.isHidden })

            let isRTL = traitCollection.layoutDirection == .rightToLeft

            for view in nonHiddenArrangedSubviews {

                if axis == .vertical {

                    switch separatorStyle {
                    case .full:
                        if view == nonHiddenArrangedSubviews.last {
                            continue
                        }
                        path.move(to: CGPoint(x: view.frame.minX, y: view.frame.maxY + 0.5 * spacing))
                        path.addLine(
                            to: CGPoint(x: view.frame.maxX, y: view.frame.maxY + 0.5 * spacing))
                    case .partial:
                        // no-op in partial
                        break
                    }

                } else {  // .horizontal

                    switch separatorStyle {
                    case .full:
                        if (!isRTL && view == nonHiddenArrangedSubviews.first)
                            || (isRTL && view == nonHiddenArrangedSubviews.last)
                        {
                            continue
                        }
                        path.move(to: CGPoint(x: view.frame.minX - 0.5 * spacing, y: view.frame.minY))
                        path.addLine(
                            to: CGPoint(x: view.frame.minX - 0.5 * spacing, y: view.frame.maxY))
                    case .partial:
                        assert(!drawBorder, "Can't combine partial separator style in a horizontal stack with draw border")
                        if 2 * StackViewWithSeparator.borderlessInset * spacing >= view.frame.width {
                            continue
                        }
                        // These values are chosen to optimize for use in STPCardFormView with borderless style
                        path.move(to: CGPoint(x: view.frame.minX +  StackViewWithSeparator.borderlessInset * spacing, y: view.frame.maxY))
                        path.addLine(
                            to: CGPoint(x: view.frame.maxX -  StackViewWithSeparator.borderlessInset * spacing, y: view.frame.maxY))
                    }

                }

            }
        }

        separatorLayer.path = path.cgPath
        backgroundView.layer.shadowPath = hideShadow ? nil :
            UIBezierPath(roundedRect: bounds, cornerRadius: borderCornerRadius).cgPath
    }

#if !canImport(CompositorServices)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // CGColor's must be manually updated when the trait collection changes
        backgroundView.layer.borderColor = borderColor.cgColor
        separatorLayer.strokeColor = separatorColor.cgColor
    }
#endif

}
