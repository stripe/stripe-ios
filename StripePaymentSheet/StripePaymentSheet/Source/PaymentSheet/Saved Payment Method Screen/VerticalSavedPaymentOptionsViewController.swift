//
//  VerticalSavedPaymentOptionsViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/7/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@_spi(STP) import StripePaymentsUI
import UIKit

/// A view controller that shows a list of saved payment methods in a vertical orientation
class VerticalSavedPaymentOptionsViewController: UIViewController {

    private let configuration: PaymentSheet.Configuration
    private let paymentMethods: [STPPaymentMethod]

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.setStyle(.back)
        navBar.delegate = self
        return navBar
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = .Localized.select_payment_method
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel] + paymentMethodRows)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = PaymentSheetUI.defaultPadding
        return stackView
    }()
    
    private lazy var paymentMethodRows: [ShadowedRoundedRectangle] = {
        return paymentMethods.map { $0.makeRowButton(appearance: configuration.appearance)}
    }()

    init(configuration: PaymentSheet.Configuration, paymentMethods: [STPPaymentMethod]) {
        self.configuration = configuration
        self.paymentMethods = paymentMethods
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)
        
        view.addAndPinSubviewToSafeArea(stackView, insets: PaymentSheetUI.defaultSheetMargins)
    }
}

// MARK: - BottomSheetContentViewController
extension VerticalSavedPaymentOptionsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        // TODO
        return true
    }

    func didTapOrSwipeToDismiss() {
        dismiss(animated: true)
    }

    var requiresFullScreen: Bool {
        // TODO
        return false
    }

    func didFinishAnimatingHeight() {
        // no-op
    }
}

// MARK: - SheetNavigationBarDelegate
extension VerticalSavedPaymentOptionsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op we are in 'back' style mode
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        _ = bottomSheetController?.popContentViewController()
    }
}

extension STPPaymentMethod {
    func makeRowButton(appearance: PaymentSheet.Appearance) -> ShadowedRoundedRectangle {
        let row = ShadowedRoundedRectangle(appearance: appearance)
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let imageView = UIImageView(image: STPImageLibrary.amexCardImage())
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = paymentSheetLabel
        label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .callout, maximumPointSize: 20)
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let circleView = CheckmarkCircleView(appearance: appearance)
        
        let stackView = UIStackView(arrangedSubviews: [imageView, label, spacer, circleView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true

        stackView.setCustomSpacing(12, after: imageView)
        
        row.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: row.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        return row
    }
}

extension UIView {
    public static var spacerView: UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        view.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return view
    }
}


class CheckmarkCircleView: UIView {
    
    let checkmarkColor: UIColor = .white
    let circleSize: CGSize = CGSize(width: 20, height: 20) // Set a default size
    
    let appearance: PaymentSheet.Appearance
    
    // Initialization
    init(appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.backgroundColor = .clear // Ensure the background is transparent
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return circleSize
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawCircle()
        drawCheckmark()
    }
    
    private func drawCircle() {
        let path = UIBezierPath(ovalIn: CGRect(origin: .zero, size: intrinsicContentSize))
        appearance.colors.primary.setFill()
        path.fill()
    }
    
    private func drawCheckmark() {
        let path = UIBezierPath()
        path.lineWidth = max(2, intrinsicContentSize.width * 0.06)
        path.move(to: CGPoint(x: intrinsicContentSize.width * 0.28, y: intrinsicContentSize.height * 0.53))
        path.addLine(to: CGPoint(x: intrinsicContentSize.width * 0.42, y: intrinsicContentSize.height * 0.66))
        path.addLine(to: CGPoint(x: intrinsicContentSize.width * 0.72, y: intrinsicContentSize.height * 0.36))
        
        checkmarkColor.setStroke()
        path.stroke()
    }
}


