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

    // #TODO - Networked Identity: localize once the final mobile copy is approved.
    enum Copy {
        static let continueButton = "Continue"
        static let manualCapture = "Manually verify identity"
        static let documentsTitle = "Choose a saved ID"
        static let documentsBody = "Select an ID to continue."
        static let documentsLoading = "Loading your saved IDs…"
        static let share = "Share ID"
        static let sharing = "Sharing your ID…"
        static let sharedTitle = "You shared your ID"
        static let sharedBody = "This ID will be used for your verification."
        static let skipping = "Continuing with manual verification…"
        static let saving = "Saving your ID…"
        static let savePreparedTitle = "You saved your ID"
        static let savePreparedBody = "Manage your saved IDs on Link."
        static let done = "Done"
        static let saveFailedTitle = "Couldn't save your ID"
        static let saveFailedBody = "Something went wrong while saving your ID to Link. Your verification isn't affected."
        static let close = "Close"

        static func documentLabel(_ document: NetworkedIdentityDocument) -> String {
            let type: String
            switch document.documentType {
            case .drivingLicense: type = "Driver's license"
            case .passport: type = "Passport"
            case .idCard: type = "Identity card"
            case .unparsable: type = "Identity document"
            }
            guard let number = document.redactedDocumentNumber, !number.isEmpty else {
                return type
            }
            return "\(type) \(number)"
        }
    }

    private let coordinator: NetworkedIdentityCoordinator
    private let flowView = IdentityFlowView()
    private let messageLabel = NetworkedIdentityFlowViewController.makeLabel()
    private let documentSelectionView = NetworkedIdentityDocumentSelectionView()
    private(set) var visibleStep: VisibleStep?
    /// The flow view already insets its content; this adds what Link's wider side margins need beyond that.
    private static var sideInset: CGFloat {
        max(0, LinkHostedSheet.contentMargins.leading - IdentityFlowView.Style.defaultContentViewInsets.leading)
    }
    /// Link's sheet takes its height from its content, and the flow view has none of its own.
    private lazy var heightConstraint: NSLayoutConstraint = {
        let constraint = view.heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .required - 1
        return constraint
    }()

    init(coordinator: NetworkedIdentityCoordinator) {
        self.coordinator = coordinator
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
            renderProgress(Copy.documentsLoading, buttons: [manualCaptureButton()])
        case .selectDocument(let documents, let selectedDocumentID):
            renderDocuments(documents, selectedDocumentID: selectedDocumentID, isSharing: false)
        case .sharingDocument(let document):
            renderDocuments([document], selectedDocumentID: document.id, isSharing: true)
        case .documentShared(let document):
            renderShared(document)
        case .skipPending:
            renderProgress(Copy.skipping, buttons: [])
        case .savePending:
            renderProgress(Copy.saving, buttons: [])
        case .savePrepared:
            renderResult(
                step: .savePrepared,
                title: Copy.savePreparedTitle,
                body: Copy.savePreparedBody,
                buttonText: Copy.done
            )
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

    func renderProgress(_ text: String, buttons: [IdentityFlowView.ViewModel.Button]) {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        let label = Self.makeLabel()
        label.text = text
        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .vertical
        stack.spacing = 16
        show(.progress, title: nil, content: stack, buttons: buttons)
    }

    func configureDocuments(
        bodyText: String,
        documents: [NetworkedIdentityDocument],
        selectedDocumentID: String?
    ) {
        documentSelectionView.configure(
            bodyText: bodyText,
            documents: documents,
            selectedDocumentID: selectedDocumentID,
            labelProvider: Copy.documentLabel,
            accessibilityLabelProvider: { document, isSelected in
                let label = Copy.documentLabel(document)
                return isSelected ? "\(label), selected" : label
            }
        )
    }

    func renderDocuments(
        _ documents: [NetworkedIdentityDocument],
        selectedDocumentID: String?,
        isSharing: Bool
    ) {
        configureDocuments(
            bodyText: isSharing ? Copy.sharing : Copy.documentsBody,
            documents: documents,
            selectedDocumentID: selectedDocumentID
        )
        let shareButton = IdentityFlowView.ViewModel.Button(
            text: Copy.share,
            state: isSharing ? .loading : (selectedDocumentID == nil ? .disabled : .enabled),
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.coordinator.shareSelectedDocument() }
        )
        show(
            .documents,
            title: Copy.documentsTitle,
            content: documentSelectionView,
            buttons: isSharing ? [shareButton] : [shareButton, manualCaptureButton()]
        )
    }

    /// The shared ID stays on screen under the confirmation; the coordinator ignores taps on it in this state.
    func renderShared(_ document: NetworkedIdentityDocument) {
        configureDocuments(bodyText: Copy.sharedBody, documents: [document], selectedDocumentID: document.id)
        show(
            .documentShared,
            title: Copy.sharedTitle,
            content: documentSelectionView,
            buttons: [continueButton(text: Copy.continueButton)]
        )
    }

    func renderResult(step: VisibleStep, title: String, body: String, buttonText: String) {
        messageLabel.text = body
        show(step, title: title, content: messageLabel, buttons: [continueButton(text: buttonText)])
    }

    func continueButton(text: String) -> IdentityFlowView.ViewModel.Button {
        .init(
            text: text,
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.coordinator.continueAfterSuccess() }
        )
    }

    func renderSaveFailed(details: String?) {
        messageLabel.text = ([Copy.saveFailedBody] + (details.map { [$0] } ?? [])).joined(separator: "\n\n")
        let closeButton = IdentityFlowView.ViewModel.Button(
            text: Copy.close,
            configuration: .networkedIdentityPrimary(),
            didTap: { [weak self] in self?.coordinator.cancel() }
        )
        show(.saveFailed, title: Copy.saveFailedTitle, content: messageLabel, buttons: [closeButton])
    }

    /// Offered until the user shares an ID or skips; saving has none, since closing the sheet is enough.
    func manualCaptureButton() -> IdentityFlowView.ViewModel.Button {
        .init(
            text: Copy.manualCapture,
            isPrimary: false,
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
        let isNewStep = visibleStep != step
        visibleStep = step
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
        if isNewStep, view.window != nil {
            UIAccessibility.post(notification: .screenChanged, argument: content)
        }
        updateHeight()
    }

    func updateHeight() {
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        heightConstraint.constant = flowView.fittingHeight(forWidth: width - 2 * Self.sideInset)
            + view.safeAreaInsets.bottom
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
