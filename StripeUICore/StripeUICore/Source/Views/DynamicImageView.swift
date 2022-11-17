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
    private let darkImage: UIImage?
    private let lightImage: UIImage?

    private var currentImage: UIImage? {
        pairedColor.resolvedColor(with: traitCollection).isDark
            ? darkImage ?? lightImage
            : lightImage ?? darkImage
    }

    public override var image: UIImage? {
        get { currentImage }
        set {
            // No-op.
        }
    }

    /// Initializes a `DynamicImageView`.
    ///
    /// - Parameters:
    ///   - lightImage: The image to show when the `pairedColor` is light.
    ///   - darkImage: The image to show when the `pairedColor` is dark.
    ///   - pairedColor: The color brightness to monitor. This should be a
    ///     `UIColor` initialized with `init(dynamicProvider:)`, otherwise the image will only be
    ///     choosen on initialization but won't change dynamically.
    public init(
        lightImage: UIImage? = nil,
        darkImage: UIImage? = nil,
        pairedColor: UIColor
    ) {
        assert(lightImage != nil || darkImage != nil)
        self.lightImage = lightImage
        self.darkImage = darkImage
        self.pairedColor = pairedColor
        // init(frame:) doesn't work for some reason and we cannot access `currentImage` yet,
        // but we can just init with a nil image since it will always use `currentImage` anyway.
        super.init(image: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
