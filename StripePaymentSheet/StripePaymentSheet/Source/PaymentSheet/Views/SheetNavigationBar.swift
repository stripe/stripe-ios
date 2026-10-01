//
//  SheetNavigationBar.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@MainActor
protocol SheetNavigationBarDelegate: AnyObject {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar)
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar)
}

/// For internal SDK use only
@objc(STP_Internal_SheetNavigationBar)
class SheetNavigationBar: UIView {

    static func height(appearance: PaymentSheet.Appearance) -> CGFloat {
        return appearance.navigationBarStyle.isGlass ? 76 : 52

    }
    weak var delegate: SheetNavigationBarDelegate?
    fileprivate lazy var leftItemsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dummyView, closeButtonLeft, backButton, testModeView])
        stack.spacing = PaymentSheetUI.defaultPadding
        stack.setCustomSpacing(PaymentSheetUI.navBarPadding(appearance: appearance), after: dummyView)
        stack.alignment = .center
        return stack
    }()
    // Used for allowing larger tap area to the left of closeButtonLeft
    fileprivate lazy var dummyView: UIView = {
        let dummyView = UIView(frame: .zero)
        return dummyView
    }()
    internal lazy var closeButtonLeft: UIButton = {
        createCloseButton()
    }()

    internal lazy var closeButtonRight: UIButton = {
        createCloseButton()
    }()

    fileprivate lazy var backButton: UIButton = {
        createBackButton()
    }()

    lazy var additionalButton: UIButton = {
        let button = NavigationBarAdditionalButton()
        button.didChange = { [weak self] in
            self?.updateSystemNavigationBar()
        }
        button.setTitleColor(appearance.colors.primary, for: .normal)
        button.setTitleColor(appearance.colors.primary.disabledColor, for: .disabled)
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.bold, style: .footnote, maximumPointSize: 20)

        return button
    }()

    var leadingElement: UIView {
        leftItemsStackView
    }

    var trailingElement: UIView? {
        if !closeButtonRight.isHidden {
            return closeButtonRight
        } else if !additionalButton.isHidden {
            return additionalButton
        }
        return nil
    }

    let testModeView = TestModeView()
    let appearance: PaymentSheet.Appearance
    let shouldLogPaymentSheetAnalyticsOnDismissal: Bool

    var usesSystemNavigationBar: Bool { systemNavigationItem != nil }
    private var currentStyle: Style = .close(showAdditionalButton: false)
    // Bind only while this content is visible; legacy bars continue to render their own controls.
    weak var systemNavigationItem: UINavigationItem? {
        didSet {
            updateSystemNavigationBar()
        }
    }
    private lazy var systemTestModeItem: UIBarButtonItem = {
        let item = UIBarButtonItem(customView: TestModeView())
        #if compiler(>=6.2) && os(iOS)
        if #available(iOS 26.0, *) {
            // TEST is a status badge, so it should not receive the glass background used by actions.
            item.hidesSharedBackground = true
        }
        #endif
        #if compiler(>=6.4) && os(iOS)
        if #available(iOS 27.1, *) {
            // Keep the badge with the controls when UIKit adapts the bar to a vertical layout.
            item.axisBehavior = .verticalPreferred
        }
        #endif
        return item
    }()

    var systemNavigationTitle: String? { nil }
    var systemNavigationTitleView: UIView? { nil }

    /// Publishes controls to the navigation controller while retaining the existing screen actions.
    func updateSystemNavigationBar() {
        guard let systemNavigationItem else { return }

        let closeItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        closeItem.isEnabled = isUserInteractionEnabled
        closeItem.accessibilityIdentifier = "UIButton.Close"
        let backItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?.imageFlippedForRightToLeftLayoutDirection(),
            style: .plain,
            target: self,
            action: #selector(didTapBackButton)
        )
        backItem.isEnabled = isUserInteractionEnabled
        backItem.accessibilityLabel = String.Localized.back
        backItem.accessibilityIdentifier = "UIButton.Back"

        let additionalItem: UIBarButtonItem
        switch additionalButton.title(for: .normal) {
        case UIButton.editButtonTitle:
            additionalItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(didTapAdditionalButton))
        case UIButton.doneButtonTitle:
            additionalItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapAdditionalButton))
        default:
            additionalItem = UIBarButtonItem(title: additionalButton.title(for: .normal), style: .plain, target: self, action: #selector(didTapAdditionalButton))
        }
        additionalItem.isEnabled = isUserInteractionEnabled && additionalButton.isEnabled
        additionalItem.accessibilityIdentifier = additionalButton.accessibilityIdentifier
        // Keep action styling instead of inheriting the navigation bar's icon appearance.
        additionalItem.tintColor = additionalButton.titleColor(for: .normal)
        for state in [UIControl.State.normal, .disabled] {
            var attributes: [NSAttributedString.Key: Any] = [:]
            if let font = additionalButton.titleLabel?.font {
                attributes[.font] = font
            }
            if let color = additionalButton.titleColor(for: state) {
                attributes[.foregroundColor] = color
            }
            additionalItem.setTitleTextAttributes(attributes, for: state)
        }

        var leadingItems: [UIBarButtonItem] = []
        var trailingItems: [UIBarButtonItem] = []
        switch currentStyle {
        case .close(let showAdditionalButton):
            if showAdditionalButton {
                leadingItems = [closeItem]
                trailingItems = [additionalItem]
            } else {
                trailingItems = [closeItem]
            }
        case .back(let showAdditionalButton):
            leadingItems = [backItem]
            trailingItems = showAdditionalButton ? [additionalItem] : []
        case .none:
            break
        }
        if !testModeView.isHidden {
            leadingItems.append(systemTestModeItem)
        }
        systemNavigationItem.leftBarButtonItems = leadingItems
        systemNavigationItem.rightBarButtonItems = trailingItems
        systemNavigationItem.title = systemNavigationTitle
        systemNavigationItem.titleView = systemNavigationTitleView
    }

    override var isUserInteractionEnabled: Bool {
        didSet {
            // Explicitly disable buttons to update their appearance
            closeButtonLeft.isEnabled = isUserInteractionEnabled
            closeButtonRight.isEnabled = isUserInteractionEnabled
            backButton.isEnabled = isUserInteractionEnabled
            additionalButton.isEnabled = isUserInteractionEnabled
            updateSystemNavigationBar()
        }
    }

    init(isTestMode: Bool, appearance: PaymentSheet.Appearance, shouldLogPaymentSheetAnalyticsOnDismissal: Bool = true) {
        testModeView.isHidden = !isTestMode
        self.appearance = appearance
        self.shouldLogPaymentSheetAnalyticsOnDismissal = shouldLogPaymentSheetAnalyticsOnDismissal
        super.init(frame: .zero)

        if appearance.navigationBarStyle.isPlain {
            backgroundColor = appearance.colors.background.withAlphaComponent(0.9)
        }

        [leftItemsStackView, closeButtonRight, additionalButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            dummyView.widthAnchor.constraint(equalToConstant: 0),
            leftItemsStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            leftItemsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftItemsStackView.trailingAnchor.constraint(lessThanOrEqualTo: closeButtonRight.leadingAnchor),
            leftItemsStackView.trailingAnchor.constraint(lessThanOrEqualTo: additionalButton.leadingAnchor),
            leftItemsStackView.heightAnchor.constraint(equalTo: heightAnchor),

            additionalButton.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.navBarPadding(appearance: appearance)),
            additionalButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            closeButtonRight.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: -PaymentSheetUI.navBarPadding(appearance: appearance)),
            closeButtonRight.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        closeButtonLeft.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        closeButtonRight.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)

        setStyle(.close(showAdditionalButton: false))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Self.height(appearance: appearance))
    }

    @objc
    private func didTapCloseButton() {
        if shouldLogPaymentSheetAnalyticsOnDismissal {
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetDismissed)
        }
        delegate?.sheetNavigationBarDidClose(self)
    }

    @objc
    private func didTapBackButton() {
        delegate?.sheetNavigationBarDidBack(self)
    }

    @objc
    private func didTapAdditionalButton() {
        additionalButton.sendActions(for: .touchUpInside)
    }

    // MARK: -
    enum Style {
        case close(showAdditionalButton: Bool)
        case back(showAdditionalButton: Bool)
        case none
    }

    func setStyle(_ style: Style) {
        currentStyle = style
        switch style {
        case .back(let showAdditionalButton):
            closeButtonLeft.isHidden = true
            closeButtonRight.isHidden = true
            additionalButton.isHidden = !showAdditionalButton
            if showAdditionalButton {
                bringSubviewToFront(additionalButton)
            }
            backButton.isHidden = false
            bringSubviewToFront(backButton)
        case .close(let showAdditionalButton):
            closeButtonLeft.isHidden = !showAdditionalButton
            closeButtonRight.isHidden = showAdditionalButton
            additionalButton.isHidden = !showAdditionalButton
            if showAdditionalButton {
                bringSubviewToFront(additionalButton)
            }
            backButton.isHidden = true
        case .none:
            closeButtonLeft.isHidden = true
            closeButtonRight.isHidden = true
            additionalButton.isHidden = true
            backButton.isHidden = true
        }
        updateSystemNavigationBar()
    }

    func setShadowHidden(_ isHidden: Bool) {
        guard !usesSystemNavigationBar else { return }
        if appearance.navigationBarStyle.isPlain {
            layer.shadowPath = CGPath(rect: bounds, transform: nil)
            layer.shadowOpacity = isHidden ? 0 : 0.1
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOffset = CGSize(width: 0, height: 2)
        }
    }
    func createBackButton() -> UIButton {
        return appearance.navigationBarStyle.isGlass ? createGlassBackButton() : createPlainBackButton()
    }
    func createPlainBackButton() -> UIButton {
        let button = SheetNavigationButton(type: .custom)
        let image = Image.icon_chevron_left_standalone.makeImage(template: true)
            .imageFlippedForRightToLeftLayoutDirection()
        button.setImage(image, for: .normal)
        button.tintColor = appearance.colors.icon
        button.accessibilityLabel = String.Localized.back
        button.accessibilityIdentifier = "UIButton.Back"
        return button
    }
    func createGlassBackButton() -> UIButton {
        let button = UIButton(type: .system)
        let size = UIButton.glassButtonSize
        button.frame = CGRect(x: 0, y: 0, width: size, height: size)
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        button.heightAnchor.constraint(equalToConstant: size).isActive = true

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)?
            .imageFlippedForRightToLeftLayoutDirection()

        button.setImage(image, for: .normal)
        button.tintColor = appearance.colors.icon

        button.accessibilityLabel = String.Localized.back
        button.accessibilityIdentifier = "UIButton.Back"
        button.ios26_applyGlassConfiguration()

        return button
    }

    func createCloseButton() -> UIButton {
        let closeButton = if appearance.navigationBarStyle.isGlass {
            UIButton.createGlassCloseButton()
        } else {
            UIButton.createPlainCloseButton()
        }
        closeButton.tintColor = appearance.colors.icon
        return closeButton
    }
}

// Existing screens mutate this button directly; mirror those updates into the system navigation item.
private final class NavigationBarAdditionalButton: UIButton {

    var didChange: (() -> Void)?

    override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        didChange?()
    }

    override var isEnabled: Bool {
        didSet {
            didChange?()
        }
    }
}

extension UIButton {

    func configureCommonEditButton(isEditingPaymentMethods: Bool, appearance: PaymentSheet.Appearance) {
        let title = isEditingPaymentMethods ? UIButton.doneButtonTitle : UIButton.editButtonTitle
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.textAlignment = .right
        titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, size: 14, maximumPointSize: 22)
        accessibilityIdentifier = "edit_saved_button"
        if appearance.navigationBarStyle.isGlass {
            ios26_applyGlassConfiguration()
        }
        // Publish the title after its styling so the native navigation item receives the final attributes.
        setTitle(title, for: .normal)
    }
}
