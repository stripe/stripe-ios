//
//  RotatingCardBrandsView.swift
//  StripePaymentSheet
//
//  Created by Eduardo Urias on 11/8/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

/// A view that displays a horizontal collection of card brand images.
///
/// For internal SDK use only
@objc(STP_Internal_RotatingCardBrandsView)
class RotatingCardBrandsView: UIView {
    static let MaxStaticBrands: Int = 3
    static let LogoSpacing: CGFloat = 3

    static let RotationInterval: TimeInterval = 3
    static let AnimationDuration: TimeInterval = 0.8

    // Use a fixed size for the rotating display, it makes
    // the constraints easier to reason about and helps if we
    // add a brand with a different size
    static let CardBrandSize: CGSize = .init(width: 26, height: 17)

    static let isUnitOrUITest: Bool = {
#if targetEnvironment(simulator)
        return NSClassFromString("XCTest") != nil || ProcessInfo.processInfo.environment["UITesting"] != nil
#else
        return false
#endif
    }()

    static let OrderIndexForCardBrand: [STPCardBrand: Int] = {
        var orders: [STPCardBrand: Int] = [:]
        for cardBrand in STPCardBrand.allCases {
            let order: Int? = {
                switch cardBrand {
                case .visa:
                    return 0
                case .mastercard:
                    return 1
                case .amex:
                    return 2
                case .discover:
                    return 3
                case .dinersClub:
                    return 4
                case .JCB:
                    return 5
                case .unionPay:
                    return 6
                // CB should not appear as one of the rotating brands.
                case .cartesBancaires:
                    return nil
                case .unknown:
                    return nil
                @unknown default:
                    return nil
                }
            }()
            if let order = order {
                orders[cardBrand] = order
            }
        }
        return orders
    }()

    public class func orderedCardBrands(from cardBrands: [STPCardBrand]) -> [STPCardBrand] {
        return cardBrands.filter( { Self.OrderIndexForCardBrand[$0] != nil } ).sorted { a, b in
            Self.OrderIndexForCardBrand[a] ?? Int.max < Self.OrderIndexForCardBrand[b] ?? Int.max
        }
    }

    var stackView: UIStackView? {
        didSet {
            if oldValue != stackView {
                oldValue?.removeFromSuperview()
                if let stackView = stackView {
                    addAndPinSubview(stackView)
                }
            }
        }
    }

    var rotatingIndex: Int = 0

    var rotatingCardBrands: [STPCardBrand] = [] {
        didSet {
            if rotatingCardBrands.isEmpty {
                rotatingCardBrandView.setHiddenIfNecessary(true)
                stopAnimating()
            } else {
                rotatingCardBrandView.setHiddenIfNecessary(false)
                rotatingIndex = 0
                self.rotatingCardBrandView.prepWithImages(
                    imageA: STPImageLibrary.cardBrandImage(for: self.rotatingCardBrands[rotatingIndex]),
                    imageB: STPImageLibrary.cardBrandImage(for: self.rotatingCardBrands[nextIndex]))
                if window != nil {
                    startAnimating()
                }
            }
        }
    }

    var isAnimating: Bool = false
    var stopAfterNextTransition = false

    var nextIndex: Int {
        var nextIndex = self.rotatingIndex + 1
        if nextIndex >= self.rotatingCardBrands.count {
            nextIndex = 0
        }
        return nextIndex
    }

    func rotateCardBrand() {
        isAnimating = true
        let animation = UIViewPropertyAnimator(duration: Self.AnimationDuration,
                                               controlPoint1: CGPoint(x: 0.19, y: 0.22),
                                               controlPoint2: CGPoint(x: 1, y: 1))
        animation.addAnimations { [weak self] in
            self?.rotatingCardBrandView.swapToB()
        }
        animation.addCompletion { [weak self] _ in
            guard let self else {
                return
            }
            self.rotatingCardBrandView.prepWithImages(
                imageA: STPImageLibrary.cardBrandImage(for: self.rotatingCardBrands[self.rotatingIndex]),
                imageB: STPImageLibrary.cardBrandImage(for: self.rotatingCardBrands[nextIndex]))
            guard !self.stopAfterNextTransition else {
                self.stopAfterNextTransition = false
                self.isAnimating = false
                return
            }
            // After completion, kick off the animation again
            DispatchQueue.main.async {
                self.rotateCardBrand()
            }
        }
        animation.startAnimation(afterDelay: Self.RotationInterval)
        self.rotatingIndex = nextIndex
    }

    func startAnimating() {
        stopAfterNextTransition = false
        guard !isAnimating,
              !rotatingCardBrands.isEmpty,
              !Self.isUnitOrUITest else {
            return
        }
        rotateCardBrand()
    }

    func stopAnimating() {
        stopAfterNextTransition = true
    }

    fileprivate var rotatingCardBrandView: RotatingABBrandView = {
        let rotatingCardBrandView = RotatingABBrandView()
        return rotatingCardBrandView
    }()

    public var cardBrands: [STPCardBrand] = [] {
        didSet {
            guard cardBrands != oldValue else {
                return
            }

            rotatingCardBrandView.contentMode = .scaleAspectFit
            rotatingCardBrandView.setContentHuggingPriority(.required, for: .horizontal)
            let cardBrandViews: [UIView] = cardBrands.prefix(Self.MaxStaticBrands).map( { brand in
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.setContentHuggingPriority(.required, for: .horizontal)
                imageView.image = STPImageLibrary.cardBrandImage(for: brand)
                return imageView
            }) + [rotatingCardBrandView]
            rotatingCardBrands = Array(cardBrands.suffix(from: min(cardBrands.count, Self.MaxStaticBrands)))

            let stackView = UIStackView(arrangedSubviews: cardBrandViews)
            stackView.spacing = Self.LogoSpacing
            stackView.alignment = .center
            stackView.translatesAutoresizingMaskIntoConstraints = false
            self.stackView = stackView
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
}

private class RotatingABBrandView: UIView {
    override var intrinsicContentSize: CGSize {
        return RotatingCardBrandsView.CardBrandSize
    }

    var viewA: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    var viewB: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(viewA)
        self.addSubview(viewB)
        viewA.translatesAutoresizingMaskIntoConstraints = false
        viewB.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewA.leftAnchor.constraint(equalTo: viewB.leftAnchor),
            viewA.rightAnchor.constraint(equalTo: viewB.rightAnchor),
            viewA.bottomAnchor.constraint(equalTo: viewB.bottomAnchor),
            viewA.topAnchor.constraint(equalTo: viewB.topAnchor),
        ])
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func swapToB() {
        viewA.alpha = 0.0
        viewB.alpha = 1.0
    }

    func prepWithImages(imageA: UIImage, imageB: UIImage) {
        viewA.image = imageA
        viewB.image = imageB
        viewA.alpha = 1.0
        viewB.alpha = 0.0
    }
}
