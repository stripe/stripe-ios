//
//  IdentityFlowView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/28/21.
//

import UIKit
@_spi(STP) import StripeUICore

/**
 Container view with a scroll view used in `IdentityFlowViewController`
 */
class IdentityFlowView: UIView {

    struct Style {
        static let contentViewInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        static let buttonInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    }

    struct ViewModel {
        let contentView: UIView
        let buttonText: String?
        let didTapButton: (() -> Void)?
        let isButtonDisabled: Bool

        init(contentView: UIView) {
            self.contentView = contentView
            self.buttonText = nil
            self.didTapButton = nil
            self.isButtonDisabled = false
        }

        init(contentView: UIView,
             buttonText: String,
             isButtonDisabled: Bool = false,
             didTapButton: @escaping () -> Void) {
            self.contentView = contentView
            self.buttonText = buttonText
            self.didTapButton = didTapButton
            self.isButtonDisabled = isButtonDisabled
        }
    }

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = CompatibleColor.systemBackground
        return scrollView
    }()

    private let buttonView: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        // TODO(mludowise|IDPROD-2738): Make a reusable button component instead of setting this here and update it to match design
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        return button
    }()

    // MARK: Configured properties

    private var contentView: UIView?
    private var buttonTapHandler: (() -> Void)?

    // MARK: - Init

    init() {
        super.init(frame: .zero)

        backgroundColor = CompatibleColor.systemGroupedBackground

        installViews()
        installConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Configures the view.

     - Note: This method changes the view hierarchy and activates new
     constraints which can affect screen render performance. It should only be
     called from a view controller's `init` or `viewDidLoad`.
     */
    func configure(with viewModel: ViewModel) {
        self.buttonTapHandler = viewModel.didTapButton
        buttonView.setTitle(viewModel.buttonText, for: .normal)
        buttonView.isHidden = (viewModel.didTapButton == nil)
        buttonView.isEnabled = !viewModel.isButtonDisabled
        buttonView.backgroundColor = viewModel.isButtonDisabled ? CompatibleColor.systemGray2 : .systemBlue
        installContentView(viewModel.contentView)
    }

    func adjustScrollViewForKeyboard(_ windowEndFrame: CGRect, isKeyboardHidden: Bool) {
        let endFrame = convert(windowEndFrame, from: window)

        // Adjust bottom inset to make space for keyboard
        let bottomInset = isKeyboardHidden ? 0 : (endFrame.height - frame.height + scrollView.frame.maxY)
        scrollView.contentInset.bottom = bottomInset
        scrollView.scrollIndicatorInsets.bottom = bottomInset
    }
}

// MARK: - Private Helpers

private extension IdentityFlowView {
    func installViews() {
        addSubview(scrollView)
        addSubview(buttonView)
    }

    func installConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        buttonView.translatesAutoresizingMaskIntoConstraints = false

        buttonView.setContentHuggingPriority(.required, for: .vertical)
        buttonView.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            // Pin scroll view to top and sides
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Make scroll view's content full-width
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),

            // Pin button to bottom and sides
            buttonView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -Style.buttonInsets.bottom),
            buttonView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: Style.buttonInsets.leading),
            buttonView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -Style.buttonInsets.trailing),

            // Space between scroll view and button
            buttonView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: Style.buttonInsets.top),
        ])
    }

    func installContentView(_ contentView: UIView) {
        guard self.contentView !== contentView else {
            // Nothing to do if view hasn't changed
            return
        }

        self.contentView?.removeFromSuperview()
        self.contentView = contentView
        scrollView.addSubview(contentView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // Pin contentView to scrollView's contentLayoutGuide
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: contentView.topAnchor, constant: -Style.contentViewInsets.top),
            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -Style.contentViewInsets.leading),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: Style.contentViewInsets.trailing),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: Style.contentViewInsets.bottom),
        ])
    }

    @objc func didTapButton() {
        self.buttonTapHandler?()
    }
}
