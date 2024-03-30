//
//  DebugView.swift
//  StripeIdentity
//
//  Created by Chen Cen on 4/18/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol DebugViewDelegate: AnyObject {
    func debugOptionsDidChange()
}

// A view to list debug options for a VS in test mode.
class DebugView: UIView {
    enum DebugButton {
        case submit(completeOption: CompleteOptionView.CompleteOption)
        case cancelled
        case failed
        case preview
    }

    struct ViewModel {
        let didTapButton: (DebugButton) -> Void
    }

    struct Styling {
        static let stackViewSpacing: CGFloat = 8
        static let buttonStackViewSpacing: CGFloat = 4
    }

    weak var delegate: DebugViewDelegate?

    private var selectedOption: CompleteOptionView.CompleteOption? {
        didSet {
            submitButton.isEnabled = selectedOption != nil
        }
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

    private let successOptionView  = CompleteOptionView(title: verificationSuccess, option: .success)
    private let failureOptionView = CompleteOptionView(title: verificationFailure, option: .failure)
    private let successAsyncOptionView = CompleteOptionView(title: verificationSuccessAsync, option: .successAsync)
    private let failureAsyncOptionView = CompleteOptionView(title: verificationFailureAsync, option: .failureAsync)

    private let submitButton: Button = Button()
    private let cancelledButton: Button = Button()
    private let failedButton: Button = Button()
    private let proceedButton: Button = Button()

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
        configureTestVerificationSection()
        addSeparator()
        configureFinishMobileFlowWithResultSection()
        addSeparator()
        configurePreviewUserExperienceSection()
        addAndPinSubviewToSafeArea(vStack)

    }

    private func configureTitleSection() {
        let warningIconView = UIImageView()
        warningIconView.contentMode = .scaleAspectFill
        warningIconView.image = Image.iconWarning.makeImage(template: true)

        NSLayoutConstraint.activate([
            warningIconView.widthAnchor.constraint(equalToConstant: 24),
            warningIconView.heightAnchor.constraint(equalToConstant: 24),
        ])

        let titleFirstLine = UILabel()
        titleFirstLine.text = DebugView.testModeTitle
        titleFirstLine.adjustsFontForContentSizeCategory = true
        titleFirstLine.font = sectionTitleFont

        let titleSecondLine = UILabel()
        titleSecondLine.numberOfLines = 0
        titleSecondLine.adjustsFontForContentSizeCategory = true
        titleSecondLine.font = sectionContentFont
        titleSecondLine.text = DebugView.testModeContent

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

    private func configureTestVerificationSection() {
        let testVerificationSectionFirstLine = UILabel()
        testVerificationSectionFirstLine.numberOfLines = 0
        testVerificationSectionFirstLine.font = sectionTitleFont
        testVerificationSectionFirstLine.text = DebugView.completeWithTestData
        vStack.addArrangedSubview(testVerificationSectionFirstLine)

        let testVerificationSectionDetails = UILabel()
        testVerificationSectionDetails.numberOfLines = 0
        testVerificationSectionDetails.font = sectionContentFont
        testVerificationSectionDetails.text = DebugView.completeWithTestDataDetails
        vStack.addArrangedSubview(testVerificationSectionDetails)

        successOptionView.delegate = self
        failureOptionView.delegate = self
        successAsyncOptionView.delegate = self
        failureAsyncOptionView.delegate = self

        addCompleteOptionView(completeOptionView: successOptionView)
        addCompleteOptionView(completeOptionView: failureOptionView)
        addCompleteOptionView(completeOptionView: successAsyncOptionView)
        addCompleteOptionView(completeOptionView: failureAsyncOptionView)

        configureButton(button: submitButton, title: DebugView.submit, action: #selector(didTapSubmit(button:)))
        submitButton.isEnabled = false

        vStack.addArrangedSubview(submitButton)

    }

    private func addCompleteOptionView(completeOptionView: CompleteOptionView) {
        let topSpacerView = UIView()
        let bottomSpacerView = UIView()

        vStack.addArrangedSubview(topSpacerView)
        vStack.addArrangedSubview(completeOptionView)
        vStack.addArrangedSubview(bottomSpacerView)
    }

    private func configureFinishMobileFlowWithResultSection() {

        let finishMobileFlowFirstLine = UILabel()
        finishMobileFlowFirstLine.numberOfLines = 0
        finishMobileFlowFirstLine.font = sectionTitleFont
        finishMobileFlowFirstLine.text = DebugView.finishMobileFlow
        vStack.addArrangedSubview(finishMobileFlowFirstLine)

        let finishMobileFlowDetails = UILabel()
        finishMobileFlowDetails.numberOfLines = 0
        finishMobileFlowDetails.font = sectionContentFont
        finishMobileFlowDetails.text = DebugView.finishMobileFlowDetails
        vStack.addArrangedSubview(finishMobileFlowDetails)

        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = Styling.buttonStackViewSpacing

        configureButton(button: cancelledButton, title: DebugView.cancelled, action: #selector(didTapCancelled(button:)))
        configureButton(button: failedButton, title: DebugView.failed, action: #selector(didTapFailed(button:)))

        buttonStack.addArrangedSubview(cancelledButton)
        buttonStack.addArrangedSubview(failedButton)

        vStack.addArrangedSubview(buttonStack)
    }

    private func configurePreviewUserExperienceSection() {
        let previewFirstLine = UILabel()
        previewFirstLine.text = DebugView.previewUserExperience
        previewFirstLine.numberOfLines = 0
        previewFirstLine.font = sectionTitleFont
        vStack.addArrangedSubview(previewFirstLine)

        let previewSecondLine = UILabel()
        previewSecondLine.text = DebugView.previewUserExperienceDetails
        previewSecondLine.numberOfLines = 0
        previewSecondLine.font = sectionContentFont
        vStack.addArrangedSubview(previewFirstLine)
        vStack.addArrangedSubview(previewSecondLine)

        configureButton(button: proceedButton, title: DebugView.proceed, action: #selector(didTapPreview(button:)))

        vStack.addArrangedSubview(proceedButton)
    }
}

extension DebugView {
    fileprivate func configureButton(button: Button, title: String, action: Selector) {
        button.title = title
        button.addTarget(self, action: action, for: .touchUpInside)
        button.configuration = .identityPrimary()
    }
}

extension DebugView {
    @objc fileprivate func didTapSubmit(button: StripeUICore.Button) {
        submitButton.isLoading = true
        cancelledButton.isEnabled = false
        failedButton.isEnabled = false
        proceedButton.isEnabled = false
        didTapButton(.submit(completeOption: selectedOption!))
    }

    @objc fileprivate func didTapCancelled(button: StripeUICore.Button) {
        submitButton.isLoading = false
        cancelledButton.isEnabled = false
        failedButton.isEnabled = false
        proceedButton.isEnabled = false
        didTapButton(.cancelled)
    }

    @objc fileprivate func didTapFailed(button: StripeUICore.Button) {
        submitButton.isLoading = false
        cancelledButton.isEnabled = false
        failedButton.isEnabled = false
        proceedButton.isEnabled = false
        didTapButton(.failed)
    }

    @objc fileprivate func didTapPreview(button: StripeUICore.Button) {
        submitButton.isLoading = false
        cancelledButton.isEnabled = false
        failedButton.isEnabled = false
        proceedButton.isEnabled = false
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

extension DebugView: CompleteOptionViewDelegate {
    func didTapOption(completeOption: CompleteOptionView.CompleteOption) {
        self.selectedOption = completeOption

        switch completeOption {
        case .success:
            successOptionView.isSelected = true
            failureOptionView.isSelected = false
            successAsyncOptionView.isSelected = false
            failureAsyncOptionView.isSelected = false
        case .failure:
            successOptionView.isSelected = false
            failureOptionView.isSelected = true
            successAsyncOptionView.isSelected = false
            failureAsyncOptionView.isSelected = false
        case .successAsync:
            successOptionView.isSelected = false
            failureOptionView.isSelected = false
            successAsyncOptionView.isSelected = true
            failureAsyncOptionView.isSelected = false
        case .failureAsync:
            successOptionView.isSelected = false
            failureOptionView.isSelected = false
            successAsyncOptionView.isSelected = false
            failureAsyncOptionView.isSelected = true
        }
    }
}

extension DebugView {
    // Debug strings, not translatable.
    static let testModeTitle: String = "You're currently in testmode"

    static let testModeContent: String = "This page is only shown in testmode."

    static let finishMobileFlow: String = "Terminate mobile SDK flow"

    static let finishMobileFlowDetails: String = "Terminate mobile SDK flow locally with Completed, Cancelled or Failed without changing the verification session on server."

    static let previewUserExperience: String = "Preview user experience"

    static let previewUserExperienceDetails: String = "Proceed to preview as an end user. Information provided will not be verified."

    static let completeWithTestData: String = "Complete with test data"

    static let completeWithTestDataDetails: String = "Save time by choosing a desired result and completing instantly with that outcome. The mobile SDK flow will return with result Completed"

    static let verificationSuccess: String = "Verification success"

    static let verificationFailure: String = "Verification failure"

    static let verificationSuccessAsync: String = "Verification success async"

    static let verificationFailureAsync: String = "Verification failure async"

    static let submit: String = "Submit"

    static let proceed: String = "Proceed"

    static let cancelled: String = "Cancelled"

    static let failed: String = "Failed"

}
