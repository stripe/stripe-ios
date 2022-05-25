//
//  CameraPreviewContainer.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/26/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class CameraPreviewContainerView: UIView {
    struct Styling {
        static let backgroundColor = IdentityUI.containerColor

        static let shadows = [
            ShadowConfiguration(
                shadowColor: .black,
                shadowOffset: CGSize(width: 0, height: 1),
                shadowOpacity: 0.12,
                shadowRadius: 1
            ),
            ShadowConfiguration(
                shadowColor: UIColor(red: 0.235, green: 0.259, blue: 0.341, alpha: 1),
                shadowOffset: CGSize(width: 0, height: 2),
                shadowOpacity: 0.08,
                shadowRadius: 5
            )
        ]
    }

    // MARK: Corner Radius

    enum CornerRadius: CGFloat {
        case medium = 12
        case large = 16
    }

    var cornerRadius: CornerRadius {
        didSet {
            contentView.layer.cornerRadius = cornerRadius.rawValue
            updateShadowBounds()
        }
    }

    // MARK: Views

    /// Container for image and camera preview
    private(set) lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = Styling.backgroundColor
        view.layer.cornerRadius = cornerRadius.rawValue
        view.clipsToBounds = true
        return view
    }()

    // MARK: Custom Layers

    /// Shadows for this view
    private let shadowLayers: [CALayer] = Styling.shadows.map { config in
        let layer = CALayer()
        config.applyTo(layer: layer)
        return layer
    }

    // MARK: - Init

    init(cornerRadius: CornerRadius = .large) {
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        addAndPinSubview(contentView)
        installShadowLayers()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: UIView

    override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowBounds()
    }

    override func addSubview(_ view: UIView) {
        assert(view === contentView, "Do not add subviews directly to CameraPreviewContainerView. Instead, add them to its contentView.")
        super.addSubview(view)
    }
}

// MARK: - Helpers

private extension CameraPreviewContainerView {
    func installShadowLayers() {
        shadowLayers.forEach { layer.addSublayer($0) }
    }

    func updateShadowBounds() {
        shadowLayers.forEach { layer in
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: cornerRadius.rawValue
            ).cgPath
        }
    }
}
