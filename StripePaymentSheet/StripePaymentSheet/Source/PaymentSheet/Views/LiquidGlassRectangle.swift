//
//  CapsuleRectangleView.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore
import UIKit

protocol SelectableRectangle: UIView {
    var appearance: PaymentSheet.Appearance { get set }
    var isSelected: Bool { get set }
    var isEnabled: Bool { get set }
}

@available(iOS 26.0, *)
class LiquidGlassRectangle: UIView, SelectableRectangle {
    private let roundedRectangle: UIView
    private let isCapsule: Bool
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

        // TODO(iOS 26): Remove this class.
        if isCapsule {
            roundedRectangle.ios26_applyCapsuleCornerConfiguration()
        } else {
            roundedRectangle.ios26_applyDefaultCornerConfiguration()
        }

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

    required init(appearance: PaymentSheet.Appearance, isCapsule: Bool) {
        self.appearance = appearance
        self.isCapsule = isCapsule
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
