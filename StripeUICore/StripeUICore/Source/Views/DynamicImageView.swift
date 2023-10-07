//
//  DynamicImageView.swift
//  StripeUICore
//
//  Created by Eduardo Urias on 11/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

/// A `UIImageView` that dynamically changes it's `image` according to the brightness of the
/// `pairedColor`.
@objc(STP_Internal_DynamicImageView)
@_spi(STP) public class DynamicImageView: UIImageView {
    private let pairedColor: UIColor
    private let dynamicImage: UIImage?

    private func makeImage(for traitCollection: UITraitCollection) -> UIImage? {
        let userInterfaceStyle: UIUserInterfaceStyle = pairedColor.resolvedColor(with: traitCollection).isDark ? .dark : .light
        let traitCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        return image?.withConfiguration(traitCollection.imageConfiguration)
    }

    /// Initializes a `DynamicImageView`.
    ///
    /// - Parameters:
    ///   - image: A UIImage with light and dark variants.
    ///   - pairedColor: The color brightness to monitor. This should be a
    ///     `UIColor` initialized with `init(dynamicProvider:)`, otherwise the image will only be
    ///     choosen on initialization but won't change dynamically.
    public init(
        dynamicImage: UIImage? = nil,
        pairedColor: UIColor
    ) {
        assert(dynamicImage != nil)
        self.dynamicImage = dynamicImage
        self.pairedColor = pairedColor
        // init(frame:) doesn't work for some reason and we cannot access `currentImage` yet,
        // so call init with a nil image and then set the right image.
        super.init(image: nil)
        image = makeImage(for: traitCollection)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        image = makeImage(for: traitCollection)
    }
}
