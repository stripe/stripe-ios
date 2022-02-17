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
        let imageContentMode: UIView.ContentMode
        let imageTintColor: UIColor?
        let backgroundColor: UIColor?
        let cornerRadius: CGFloat
        let shadowConfiguration: ShadowConfiguration
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
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
        imageView.contentMode = viewModel.imageContentMode
        imageView.backgroundColor = viewModel.backgroundColor
        imageView.tintColor = viewModel.imageTintColor
        imageView.layer.cornerRadius = viewModel.cornerRadius

        viewModel.shadowConfiguration.applyTo(layer: layer)

        // Update to match new cornerRadius
        updateShadowPath()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update to match new bounds
        updateShadowPath()
    }

    private func updateShadowPath() {
        // Set the view's shadow layer + set the shadow configuration
        // Set the shadow layer to be the same path as the image
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: imageView.layer.cornerRadius).cgPath

    }
}
