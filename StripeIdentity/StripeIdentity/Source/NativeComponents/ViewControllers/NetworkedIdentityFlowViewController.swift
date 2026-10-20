//
//  NetworkedIdentityFlowViewController.swift
//  StripeIdentity
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentSheet
@_spi(STP) import StripeUICore
import UIKit

/// The content of Identity's Link sheet: renders `NetworkedIdentityCoordinator` states and forwards user
/// actions to it. `LinkHostedSheet` supplies the sheet itself, with Link's header and close button.
@MainActor
final class NetworkedIdentityFlowViewController: UIViewController {
    enum VisibleStep: Equatable {
        case progress
        case documents
        case documentShared
        case savePrepared
        case saveFailed
    }

    private let coordinator: NetworkedIdentityCoordinator
    private let includesSelfie: Bool
    private let flowView = IdentityFlowView()
    private let messageLabel = NetworkedIdentityFlowViewController.makeLabel()
    private let documentSelectionView = NetworkedIdentityDocumentSelectionView()
    /// "ID and selfie saved", in Link's colors and type. It's shown instead of the flow view, whose buttons can't be
    /// spaced as the design is.
    private lazy var savedView = makeSavedView()
    private(set) var visibleStep: VisibleStep?
    /// The flow view already insets its content; this adds what Link's wider side margins need beyond that.
    private static var sideInset: CGFloat {
        max(0, LinkHostedSheet.contentMargins.leading - IdentityFlowView.Style.defaultContentViewInsets.leading)
    }
    /// The design's padding around the saved view, with Link's side margins.
    private static var savedViewInsets: NSDirectionalEdgeInsets {
        .init(
            top: 24,
            leading: LinkHostedSheet.contentMargins.leading,
            bottom: 20,
            trailing: LinkHostedSheet.contentMargins.trailing
        )
    }
    /// Link's sheet takes its height from its content, and the flow view has none of its own.
    private lazy var heightConstraint: NSLayoutConstraint = {
        let constraint = view.heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .required - 1
        return constraint
    }()

    init(coordinator: NetworkedIdentityCoordinator, includesSelfie: Bool) {
        self.coordinator = coordinator
        self.includesSelfie = includesSelfie
        super.init(nibName: nil, bundle: nil)

        documentSelectionView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        view.addAndPinSubview(
            flowView,
            insets: .init(top: 0, leading: Self.sideInset, bottom: 0, trailing: Self.sideInset)
        )
        flowView.tintColor = .label
        // Sized by its content, from which `updateHeight` sizes the sheet.
        savedView.isHidden = true
        savedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(savedView)
        NSLayoutConstraint.activate([
            savedView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Self.savedViewInsets.top),
            savedView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Self.savedViewInsets.leading),
            savedView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Self.savedViewInsets.trailing),
        ])
        render(coordinator.state)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateHeight()
    }

    func render(_ state: NetworkedIdentityState) {
        guard isViewLoaded else {
            return
        }
        switch state {
        case .idle, .preparing, .linkAuthentication, .fullCaptureFallback, .cancelled:
            break
        case .documentsPending:
            renderProgress(Strings.documentsLoading, buttons: [manualCaptureButton()])
        case .selectDocument(let documents, let selectedDocumentID):
            renderDocuments(documents, selectedDocumentID: selectedDocumentID, isSharing: false)
        case .sharingDocument(let document):
            renderDocuments([document], selectedDocumentID: document.id, isSharing: true)
        case .documentShared(let document):
            renderShared(document)
        case .skipPending:
            renderProgress(Strings.skipping, buttons: [])
        case .savePending:
            renderProgress(Strings.saving, title: Strings.continueWithLink, buttons: [])
        case .savePrepared:
            renderSaved()
        case .saveFailed(let details):
            renderSaveFailed(details: details)
        }
    }
}

// MARK: - Rendering

private extension NetworkedIdentityFlowViewController {
    static func makeLabel() -> UILabel {
        let label = UILabel()
        label.font = NetworkedIdentityUI.bodyFont
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    func renderProgress(_ text: String, title: String? = nil, buttons: [IdentityFlowView.ViewModel.Button]) {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        let label = Self.makeLabel()
        label.text = text
        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .vertical
        stack.spacing = 16
        show(.progress, title: title, content: stack, buttons: buttons)
    }

    func renderDocuments(
        _ documents: [NetworkedIdentityDocument],
        selectedDocumentID: String?,
        isSharing: Bool
    ) {
        documentSelectionView.configure(
            bodyText: isSharing ? Strings.sharing : Strings.documentsBody,
            documents: documents,
            selectedDocumentID: selectedDocumentID
        )
        let shareButton = IdentityFlowView.ViewModel.Button(
            text: Strings.share,
            state: isSharing ? .loading : (selectedDocumentID == nil ? .disabled : .enabled),
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.coordinator.shareSelectedDocument() }
        )
        show(
            .documents,
            title: Strings.documentsTitle,
            content: documentSelectionView,
            buttons: isSharing ? [shareButton] : [shareButton, manualCaptureButton()]
        )
    }

    /// The shared ID stays on screen under the confirmation; the coordinator ignores taps on it in this state.
    func renderShared(_ document: NetworkedIdentityDocument) {
        documentSelectionView.configure(bodyText: Strings.sharedBody, documents: [document], selectedDocumentID: document.id)
        show(
            .documentShared,
            title: Strings.sharedTitle,
            content: documentSelectionView,
            buttons: [
                .init(
                    text: Strings.continueButton,
                    configuration: .networkedIdentityPrimary(),
                    didTap: { [weak self] in self?.coordinator.continueAfterSuccess() }
                ),
            ]
        )
    }

    func renderSaved() {
        flowView.isHidden = true
        savedView.isHidden = false
        didShow(.savePrepared, content: savedView)
    }

    func makeSavedView() -> UIView {
        let badge = UIImageView(image: Image.linkSaved.makeImage())
        badge.contentMode = .center

        let title = UILabel()
        title.font = NetworkedIdentityUI.titleFont
        title.textColor = NetworkedIdentityUI.linkPrimaryColor
        title.textAlignment = .center
        title.numberOfLines = 0
        title.accessibilityTraits = .header
        title.setText(
            Strings.savePreparedTitle(includesSelfie: includesSelfie),
            lineHeight: NetworkedIdentityUI.titleLineHeight
        )

        let body = UILabel()
        body.font = NetworkedIdentityUI.bodyFont
        body.textColor = NetworkedIdentityUI.linkTextTertiaryColor
        body.textAlignment = .center
        body.numberOfLines = 0
        body.setText(
            Strings.savePreparedBody(includesSelfie: includesSelfie),
            lineHeight: NetworkedIdentityUI.bodyLineHeight
        )

        let doneButton = Button(configuration: .networkedIdentityDone(), title: Strings.done)
        doneButton.addAction(UIAction { [weak self] _ in self?.coordinator.continueAfterSuccess() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [badge, title, body, doneButton])
        stack.axis = .vertical
        stack.setCustomSpacing(24, after: badge)
        stack.setCustomSpacing(4, after: title)
        // The content's bottom padding, then the button's top padding.
        stack.setCustomSpacing(16 + 20, after: body)
        return stack
    }

    func renderSaveFailed(details: String?) {
        messageLabel.text = ([Strings.saveFailedBody] + (details.map { [$0] } ?? [])).joined(separator: "\n\n")
        let closeButton = IdentityFlowView.ViewModel.Button(
            text: Strings.close,
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.coordinator.cancel() }
        )
        show(.saveFailed, title: Strings.saveFailedTitle, content: messageLabel, buttons: [closeButton])
    }

    /// Offered until the user shares an ID or skips; saving has none, since closing the sheet is enough.
    func manualCaptureButton() -> IdentityFlowView.ViewModel.Button {
        .init(
            text: Strings.manualCapture,
            configuration: .networkedIdentitySecondary(),
            didTap: { [weak self] in self?.coordinator.chooseManualCapture() }
        )
    }

    func show(
        _ step: VisibleStep,
        title: String?,
        content: UIView,
        buttons: [IdentityFlowView.ViewModel.Button]
    ) {
        do {
            try flowView.configure(
                with: .init(
                    headerViewModel: title.map {
                        HeaderView.ViewModel(
                            backgroundColor: .systemBackground,
                            headerType: .plain,
                            titleText: $0,
                            titleFont: NetworkedIdentityUI.titleFont,
                            titleTextColor: .label,
                            topInset: NetworkedIdentityUI.compactHeaderTopInset
                        )
                    },
                    contentView: content,
                    buttons: buttons
                )
            )
        } catch {
            stpAssertionFailure("Networked Identity flow configuration failed: \(error)")
        }
        flowView.isHidden = false
        savedView.isHidden = true
        didShow(step, content: content)
    }

    /// Announces `step` when it's new, and fits the sheet to it.
    func didShow(_ step: VisibleStep, content: UIView) {
        let isNewStep = visibleStep != step
        visibleStep = step
        if isNewStep, view.window != nil {
            UIAccessibility.post(notification: .screenChanged, argument: content)
        }
        updateHeight()
    }

    func updateHeight() {
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        let contentHeight = savedView.isHidden
            ? flowView.fittingHeight(forWidth: width - 2 * Self.sideInset)
            : Self.savedViewInsets.top
                + savedView.systemLayoutSizeFitting(
                    CGSize(
                        width: width - Self.savedViewInsets.leading - Self.savedViewInsets.trailing,
                        height: UIView.layoutFittingCompressedSize.height
                    ),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                ).height
                + Self.savedViewInsets.bottom
        heightConstraint.constant = contentHeight + view.safeAreaInsets.bottom
        heightConstraint.isActive = true
    }
}

// MARK: - NetworkedIdentityDocumentSelectionViewDelegate

extension NetworkedIdentityFlowViewController: @MainActor NetworkedIdentityDocumentSelectionViewDelegate {
    func networkedIdentityDocumentSelectionView(
        _ view: NetworkedIdentityDocumentSelectionView,
        didSelect document: NetworkedIdentityDocument
    ) {
        coordinator.selectDocument(document)
    }
}
