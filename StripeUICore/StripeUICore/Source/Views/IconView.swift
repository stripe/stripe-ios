//
//  IconView.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 5/25/22.
//

import UIKit

@objc(STP_Internal_IconView)
@_spi(STP) public class IconView: UIView {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        addAndPinSubview(imageView)
        return imageView
    }()

    public required init(image: UIImage) {
        super.init(frame: .zero)
        imageView.image = image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
