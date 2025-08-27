//
//  CapsuleRectangleView.swift
//  StripePaymentSheet
//
//  Created by John Woo on 8/26/25.
//

@_spi(STP) import StripeUICore
import UIKit

@available(iOS 26.0, *)
class CapsuleRectangle: UIView, SelectableRectangle {
    private let roundedRectangle: UIView
    var appearance: PaymentSheet.Appearance {
        didSet {
            update()
        }
    }

    var isEnabled: Bool = true {
        didSet {
            update()
        }
    }

    var isSelected: Bool = false {
        didSet {
            update()
        }
    }

    /// All mutations to this class should route to this single method to update the UI
    private func update() {
        // Background color
        if isEnabled {
            roundedRectangle.backgroundColor = appearance.colors.componentBackground
        } else {
            roundedRectangle.backgroundColor = appearance.colors.componentBackground.disabledColor
        }
        #if compiler(>=6.2)
        roundedRectangle.cornerConfiguration = .capsule()
        #endif

        // Border
        if isSelected {
            let selectedBorderWidth = appearance.selectedBorderWidth ?? appearance.borderWidth
            if selectedBorderWidth > 0 {
                roundedRectangle.layer.borderWidth = selectedBorderWidth * 1.5
            } else {
                // Without a border, the customer can't tell this is selected and it looks bad
                roundedRectangle.layer.borderWidth = 1.5
            }
            roundedRectangle.layer.borderColor = appearance.colors.selectedComponentBorder?.cgColor ?? appearance.colors.primary.cgColor
        } else {
            roundedRectangle.layer.borderWidth = 0
            roundedRectangle.layer.borderColor = nil
        }
    }

    required init(appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        roundedRectangle = UIView()
        roundedRectangle.layer.masksToBounds = true
        super.init(frame: .zero)
        addAndPinSubview(roundedRectangle)
        update()
    }

    #if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        update()
    }
    #endif

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
