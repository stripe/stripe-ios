//
//  InstructionalCameraScanningView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/8/21.
//

import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCameraCore

/**
 A view that displays instructions to the user underneath a live camera feed.
 The view can be configured such that it can either display a live camera feed or
 a static image in place of the camera feed.

- Note:
 TODO(mludowise|IDPROD-2774): We need to migrate & refactor some camera code
 before this will display a video feed.

 TODO(mludowise|IDPROD-2756): This UI will be updated and polished when designs
 have been finalized.
 */
final class InstructionalCameraScanningView: UIView {

    struct Styling {
        static let containerBackgroundColor = CompatibleColor.systemGray6
        static let containerCornerRadius: CGFloat = 16
        static let labelFont = UIFont.preferredFont(forTextStyle: .body)
        static let spacing: CGFloat = 16
        static let containerAspectRatio: CGFloat = 4.0 / 5.0
    }

    struct ViewModel {
        enum State {
            case staticImage(UIImage, contentMode: UIView.ContentMode)
            case videoPreview
        }

        let state: State
        let instructionalText: String
    }

    // MARK: Views

    let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Styling.labelFont
        return label
    }()

    let cameraFeedContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Styling.containerBackgroundColor
        view.layer.cornerRadius = Styling.containerCornerRadius
        view.clipsToBounds = true
        return view
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = Styling.spacing
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()

    // MARK: Init

    init() {
        super.init(frame: .zero)
        installViews()
        installConstraints()
    }

    convenience init(from viewModel: ViewModel) {
        self.init()
        configure(with: viewModel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel) {
        label.text = viewModel.instructionalText

        switch viewModel.state {
        case .staticImage(let image, let contentMode):
            imageView.isHidden = false
            imageView.image = image
            imageView.contentMode = contentMode
        case .videoPreview:
            imageView.isHidden = true
            imageView.image = nil
            // TODO(mludowise|IDPROD-2774,IDPROD-2756): Display video preview
        }
    }
}

// MARK: - Helpers

private extension InstructionalCameraScanningView {
    func installViews() {
        addAndPinSubview(vStack)
        cameraFeedContainerView.addAndPinSubview(imageView)
        vStack.addArrangedSubview(cameraFeedContainerView)
        vStack.addArrangedSubview(label)
    }

    func installConstraints() {
        NSLayoutConstraint.activate([
            cameraFeedContainerView.heightAnchor.constraint(equalTo: cameraFeedContainerView.widthAnchor, multiplier: Styling.containerAspectRatio)
        ])
    }
}
