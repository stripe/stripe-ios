//
//  ShadowedCorneredImageView.swift
//  StripeIdentity
//
//  Created by Jaime Park on 2/1/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// The shadowed rounded image view.
/// Can't set a corner radius and shadow to a single view since `maskToBound` value will conflict.
/// For internal SDK use only
class ShadowedCorneredImageView: UIView {

    struct ViewModel {
        let image: UIImage
        let cornerRadius: CGFloat
        let shadowConfiguration: ShadowConfiguration
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        // Default set all image mode to .scaleAspectFill
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    // MARK: - Inits
    init() {
        super.init(frame: .zero)
        addAndPinSubview(imageView)
    }

    convenience init(with viewModel: ViewModel) {
        self.init()
        configure(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: ViewModel) {
        // Create an image view + set corner radius
        imageView.image = viewModel.image
        imageView.layer.cornerRadius = viewModel.cornerRadius
        imageView.layer.masksToBounds = true

        // Set the view's shadow layer + set the shadow configuration
        // Set the shadow layer to be the same path as the image
        layer.shadowPath = UIBezierPath(rect: imageView.bounds).cgPath
        viewModel.shadowConfiguration.applyTo(layer: layer)
    }
}
