//
//  STPCardScannerTableViewCell.swift
//  Stripe
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

@available(macCatalyst 14.0, *)
class STPCardScannerTableViewCell: UITableViewCell {
    private(set) weak var cameraView: STPCameraView?

    private var _theme: STPTheme?
    var theme: STPTheme? {
        get {
            _theme
        }
        set(theme) {
            _theme = theme
            updateAppearance()
        }
    }

    let cardSizeRatio: CGFloat = 2.125 / 3.370  // ID-1 card size (in inches)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let cameraView = STPCameraView(frame: bounds)
        contentView.addSubview(cameraView)
        self.cameraView = cameraView
        theme = STPTheme.defaultTheme
        self.cameraView?.translatesAutoresizingMaskIntoConstraints = false
        contentView.addConstraints(
            [
                cameraView.heightAnchor.constraint(
                    equalTo: cameraView.widthAnchor, multiplier: cardSizeRatio),
                cameraView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
                cameraView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
                cameraView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: 0),
                cameraView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            ])
        updateAppearance()
    }

    override func layoutSubviews() {

        super.layoutSubviews()
    }

    @objc func updateAppearance() {
        // The first few frames of the camera view will be black, so our background should be black too.
        cameraView?.backgroundColor = UIColor.black
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
