//
//  DebugView.swift
//  StripeIdentity
//
//  Created by Chen Cen on 4/18/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// A view to list debug options for a VS in test mode.
class DebugView: UIView {
    enum DebugButton {
        case completed
        case cancelled
        case failed
        case preview
    }

    struct ViewModel {
        let didTapButton: (DebugButton) -> Void
    }

    struct Styling {
        static let stackViewSpacing: CGFloat = 8
    }

    // MARK: - properties
    private var didTapButton: (DebugButton) -> Void = { _ in }

    // MARK: - views
    private let vStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Styling.stackViewSpacing
        return stack
    }()

    // MARK: - Inits
    init() {
        super.init(frame: .zero)
        installViews()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel) {
        self.didTapButton = viewModel.didTapButton
    }

    private func installViews() {
        configureTitleSection()
        addSeparator()
        configureFinishMobileFlowWithResultSection()
        addSeparator()
        configurePreviewUserExperienceSection()
        addAndPinSubviewToSafeArea(vStack)

    }

    private func configureTitleSection() {
        let warningIconView = UIImageView()
        warningIconView.contentMode = .scaleAspectFill
        warningIconView.image = Image.iconWarning.makeImage().withTintColor(warningIconView.tintColor)
        NSLayoutConstraint.activate([
            warningIconView.widthAnchor.constraint(equalToConstant: 24),
            warningIconView.heightAnchor.constraint(equalToConstant: 24),
        ])

        let titleFirstLine = UILabel()
        titleFirstLine.text = .Localized.testModeTitle
        titleFirstLine.adjustsFontForContentSizeCategory = true
        titleFirstLine.font = sectionTitleFont

        let titleSecondLine = UILabel()
        titleSecondLine.numberOfLines = 0
        titleSecondLine.adjustsFontForContentSizeCategory = true
        titleSecondLine.font = sectionContentFont
        titleSecondLine.text = .Localized.testModeContent

        let titleTextVstack = UIStackView(arrangedSubviews: [titleFirstLine, titleSecondLine])
        titleTextVstack.axis = .vertical

        let titleHstack = UIStackView(arrangedSubviews: [warningIconView, titleTextVstack])
        titleHstack.axis = .horizontal
        titleHstack.spacing = Styling.stackViewSpacing
        titleHstack.alignment = .center

        vStack.addArrangedSubview(titleHstack)
    }

    private func addSeparator() {
        let topSpacerView = UIView()
        let separator = UIView()
        separator.backgroundColor = IdentityUI.separatorColor
        let bottomSpacerView = UIView()

        vStack.addArrangedSubview(topSpacerView)
        vStack.addArrangedSubview(separator)
        vStack.addArrangedSubview(bottomSpacerView)

        NSLayoutConstraint.activate([
            topSpacerView.heightAnchor.constraint(equalToConstant: Styling.stackViewSpacing),
            separator.heightAnchor.constraint(equalToConstant: IdentityUI.separatorHeight),
            separator.leadingAnchor.constraint(equalTo: vStack.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: vStack.trailingAnchor),
            bottomSpacerView.heightAnchor.constraint(equalToConstant: Styling.stackViewSpacing),
        ])
    }

    private func configureFinishMobileFlowWithResultSection() {

        let finishMobileFlowFirstLine = UILabel()
        finishMobileFlowFirstLine.numberOfLines = 0
        finishMobileFlowFirstLine.font = sectionTitleFont
        finishMobileFlowFirstLine.text = .Localized.finishMobileFlow
        vStack.addArrangedSubview(finishMobileFlowFirstLine)

        let finishMobileFlowSecondLine = UILabel()
        finishMobileFlowSecondLine.numberOfLines = 0
        finishMobileFlowSecondLine.font = sectionContentFont
        finishMobileFlowSecondLine.text = .Localized.finishMobileFlowDetails
        vStack.addArrangedSubview(finishMobileFlowSecondLine)

        vStack.addArrangedSubview(
            Button(
                title: "Completed",
                target: self,
                action: #selector(didTapCompleted(button:))
            )
        )

        vStack.addArrangedSubview(
            Button(
                title: "Cancelled",
                target: self,
                action: #selector(didTapCancelled(button:))
            )
        )

        vStack.addArrangedSubview(
            Button(
                title: "Failed",
                target: self,
                action: #selector(didTapFailed(button:))
            )
        )
    }

    private func configurePreviewUserExperienceSection() {
        let previewFirstLine = UILabel()
        previewFirstLine.text = .Localized.previewUserExperience
        previewFirstLine.numberOfLines = 0
        previewFirstLine.font = sectionTitleFont
        vStack.addArrangedSubview(previewFirstLine)

        let previewSecondLine = UILabel()
        previewSecondLine.text = .Localized.previewUserExperienceDetails
        previewSecondLine.numberOfLines = 0
        previewSecondLine.font = sectionContentFont
        vStack.addArrangedSubview(previewFirstLine)
        vStack.addArrangedSubview(previewSecondLine)

        vStack.addArrangedSubview(
            Button(
                title: .Localized.proceed,
                target: self,
                action: #selector(didTapPreview(button:))
            )
        )
    }

}

extension StripeUICore.Button {
    fileprivate convenience init(
        title: String,
        target: Any?,
        action: Selector
    ) {
        self.init()
        self.title = title
        addTarget(target, action: action, for: .touchUpInside)
        self.configuration = .identityPrimary()
    }
}

extension DebugView {
    @objc fileprivate func didTapCompleted(button: StripeUICore.Button) {
        didTapButton(.completed)
    }

    @objc fileprivate func didTapCancelled(button: StripeUICore.Button) {
        didTapButton(.cancelled)
    }

    @objc fileprivate func didTapFailed(button: StripeUICore.Button) {
        didTapButton(.failed)
    }

    @objc fileprivate func didTapPreview(button: StripeUICore.Button) {
        didTapButton(.preview)
    }
}

extension DebugView {
    fileprivate var sectionTitleFont: UIFont {
        IdentityUI.preferredFont(forTextStyle: .headline, weight: .medium)
    }

    fileprivate var sectionContentFont: UIFont {
        IdentityUI.instructionsFont
    }
}
