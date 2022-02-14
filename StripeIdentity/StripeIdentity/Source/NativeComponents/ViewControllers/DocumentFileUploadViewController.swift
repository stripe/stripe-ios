//
//  DocumentFileUploadViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 1/11/22.
//

import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

@available(iOSApplicationExtension, unavailable)
final class DocumentFileUploadViewController: IdentityFlowViewController {

    typealias DocumentType = VerificationPageDataIDDocument.DocumentType

    struct Styling {
        static let uploadCompleteIcon = Image.iconCheckmark.makeImage(template: true)
    }

    // MARK: - Instance Properties

    let imageLoadingQueue = DispatchQueue(label: "com.stripe.identity.document-image-loading")

    let fileUploadView = FileUploadView()

    /// The document type selected by the user
    let documentType: DocumentType

    /// If the image must come from a live camera feed
    let requireLiveCapture: Bool

    private(set) var currentlySelectingSide: DocumentSide?

    /// If the front image file is loading from the file system
    private(set) var isLoadingFrontImageFile = false
    /// If the back image file is loading from the file system
    private(set) var isLoadingBackImageFile = false

    /// True while waiting for `saveDocumentFileData` to complete
    private(set) var isSavingDocumentFileData = false {
        didSet {
            updateUI()
        }
    }

    // MARK: - Coordinators

    let documentUploader: DocumentUploaderProtocol
    let cameraPermissionsManager: CameraPermissionsManagerProtocol
    let appSettingsHelper: AppSettingsHelperProtocol

    // MARK: - View Model

    var viewModel: FileUploadView.ViewModel {
        var items = [
            ListItemView.ViewModel(
                text: listItemText(for: .front),
                accessibilityLabel: accessibilityLabel(for: .front, uploadStatus: documentUploader.frontUploadStatus),
                accessory: listItemAccessory(
                    for: .front,
                       isLoadingImageFile: isLoadingFrontImageFile,
                       uploadStatus: documentUploader.frontUploadStatus
                ),
                onTap: nil
            )
        ]
        if documentType != .passport {
            items.append(.init(
                text: listItemText(for: .back),
                accessibilityLabel: accessibilityLabel(for: .back, uploadStatus: documentUploader.backUploadStatus),
                accessory: listItemAccessory(
                    for: .back,
                       isLoadingImageFile: isLoadingBackImageFile,
                       uploadStatus: documentUploader.backUploadStatus
                ),
                onTap: nil
            ))
        }

        return .init(
            instructionText: instructionText,
            listViewModel: .init(items: items)
        )
    }

    var buttonState: IdentityFlowView.ViewModel.Button.State {
        switch (
            isSavingDocumentFileData,
            documentUploader.frontUploadStatus,
            documentUploader.backUploadStatus, documentType.hasBack
        ) {
          case (true, _, _, _):
            // Show loading indicator if the document is being saved
            return .loading
          case (false, .complete, .complete, true),
               (false, .complete, _, false):
            // Button should be enabled if either both front and back uploads are
            // complete, or if the document has no back and front upload is complete
            return .enabled
          default:
            return .disabled
        }
    }

    // MARK: - Init

    init(
        documentType: DocumentType,
        requireLiveCapture: Bool,
        sheetController: VerificationSheetControllerProtocol,
        documentUploader: DocumentUploaderProtocol,
        cameraPermissionsManager: CameraPermissionsManagerProtocol = CameraPermissionsManager.shared,
        appSettingsHelper: AppSettingsHelperProtocol = AppSettingsHelper.shared
    ) {
        self.documentType = documentType
        self.requireLiveCapture = requireLiveCapture
        self.documentUploader = documentUploader
        self.cameraPermissionsManager = cameraPermissionsManager
        self.appSettingsHelper = appSettingsHelper
        super.init(sheetController: sheetController)

        documentUploader.delegate = self

        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    func updateUI() {
        fileUploadView.configure(with: viewModel)

        configure(
            backButtonTitle: STPLocalizedString(
                "Upload",
                "Back button label for the identity document file upload screen"
            ),
            viewModel: .init(
                headerViewModel: .init(
                    backgroundColor: CompatibleColor.systemBackground,
                    headerType: .plain,
                    titleText: STPLocalizedString(
                        "File upload",
                        "Title of identity document file upload screen"
                    )
                ),
                contentViewModel: .init(
                    view: fileUploadView,
                    inset: .zero),
                buttons: [.continueButton(
                    state: buttonState,
                    didTap: { [weak self] in
                        self?.didTapContinueButton()
                    }
                )]
            )
        )
    }

    /// Focuses the accessibility VoiceOver on the list item for the given document side
    func focusAccessibilityOnListItem(for side: DocumentSide) {
        fileUploadView.listView.focusAccessibility(onItemIndex: (side == .front) ? 0 : 1)
    }

    func listItemAccessory(
        for side: DocumentSide,
        isLoadingImageFile: Bool,
        uploadStatus: DocumentUploader.UploadStatus
    ) -> ListItemView.ViewModel.Accessory {
        // Show activity indicator if we're still loading the file from the file system
        if isLoadingImageFile {
            return .activityIndicator
        }

        switch uploadStatus {
        case .notStarted,
             .error:
            // TODO(IDPROD-3114|mludowise): Migrate "Select" localized string to StripeUICore
            return .button(
                title: "Select",
                onTap: { [weak self] in
                    self?.didTapSelect(for: side)
                }
            )
        case .inProgress:
            return .activityIndicator
        case .complete:
            return .icon(
                Styling.uploadCompleteIcon
            )
        }
    }

    func setIsLoadingImageFromFile(
        _ value: Bool,
        for side: DocumentSide
    ) {
        switch side {
        case .front:
            isLoadingFrontImageFile = value
        case .back:
            isLoadingBackImageFile = value
        }
    }

    // MARK: - File selection

    func didTapSelect(for side: DocumentSide) {
        currentlySelectingSide = side

        let message: String?
        switch (requireLiveCapture, side) {
        case (true, _):
            message = nil
        case (false, .front):
            message = STPLocalizedString(
                "Select a location to upload the front of your identity document from",
                "Help text for action sheet that presents ways to upload the front of an identity document image"
            )
        case (false, .back):
            message = STPLocalizedString(
                "Select a location to upload the back of your identity document from",
                "Help text for action sheet that presents ways to upload the back of an identity document image"
            )
        }

        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .actionSheet
        )

        if !requireLiveCapture && UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(.init(
                title: STPLocalizedString(
                    "Photo Library",
                    "When selected in an action sheet, opens the device's photo library"
                ),
                style: .default,
                handler: { [weak self] _ in
                    self?.selectPhotoFromLibrary()
                }
            ))
        }

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(.init(
                title: STPLocalizedString(
                    "Take Photo",
                    "When selected in an action sheet, opens the device's camera interface"
                ),
                style: .default,
                handler: { [weak self] _ in
                    self?.takePhoto()
                }
            ))
        }

        if !requireLiveCapture {
            alert.addAction(.init(
                title: STPLocalizedString(
                    "Choose File",
                    "When selected in an action sheet, opens the device's file system browser"
                ),
                style: .default,
                handler: { [weak self] _ in
                    self?.selectFileFromSystem()
                }
            ))
        }

        // TODO(IDPROD-3114|mludowise): Migrate "Cancel" localized string to StripeUICore
        alert.addAction(.init(
            title: "Cancel",
            style: .cancel
        ))

        present(alert, animated: true, completion: nil)
    }

    func selectPhotoFromLibrary() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            // TODO(IDPROD-2816): log error
            return
        }

        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }

    func takePhoto() {
        // Check for camera permissions first.
        cameraPermissionsManager.requestCameraAccess(completeOnQueue: .main) { [weak self] granted in
            guard let self = self else { return }
            guard granted == true else {
                self.showCameraPermissionsAlert()
                return
            }

            guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                // TODO(IDPROD-2816): log error
                return
            }

            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }

    func selectFileFromSystem() {
        let documentPicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            // NOTE: We must request a copy of the image because the original
            // will likely be outside of this app's sandbox.
            documentPicker = UIDocumentPickerViewController(
                forOpeningContentTypes: [.image],
                asCopy: true
            )
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: ["public.image", "public.jpeg", "public.png"], in: UIDocumentPickerMode.import)
        }
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }

    func upload(
        image: UIImage,
        for side: DocumentSide,
        method: VerificationPageDataDocumentFileData.FileUploadMethod
    ) {
        guard let ciImage = CIImage(image: image) else {
            // TODO(IDPROD-2816): log error
            return
        }

        documentUploader.uploadImages(
            for: side,
            originalImage: ciImage,
            idDetectorOutput: nil,
            method: method
        )
    }

    func showCameraPermissionsAlert() {
        let alert = UIAlertController(
            title: STPLocalizedString(
                "Camera permission",
                "Title displayed when requesting camera permissions"
            ),
            message: STPLocalizedString(
                "We need permission to use your camera. Please allow camera access in app settings.",
                "Text displayed when requesting camera permissions"
            ),
            preferredStyle: .alert
        )

        if appSettingsHelper.canOpenAppSettings {
            alert.addAction(.init(
                title: String.Localized.app_settings,
                style: .default,
                handler: { [weak self] _ in
                    self?.appSettingsHelper.openAppSettings()
                }
            ))
        }

        // TODO(IDPROD-3114|mludowise): Migrate "OK" localized string to StripeUICore
        alert.addAction(.init(
            title: "OK",
            style: .cancel,
            handler: nil
        ))

        present(alert, animated: true, completion: nil)
    }

    // MARK: - Continue button

    func didTapContinueButton() {
        isSavingDocumentFileData = true
        sheetController?.saveDocumentFileData(documentUploader: documentUploader, completion: { [weak self] apiContent in
            guard let self = self,
                  let sheetController = self.sheetController
            else {
                return
            }

            sheetController.flowController.transitionToNextScreen(
                apiContent: apiContent,
                sheetController: sheetController,
                completion: { [weak self] in
                    self?.isSavingDocumentFileData = false
                }
            )
        })
    }

    // MARK: - Testing

    #if DEBUG

    /* NOTE:
     Since `presentedViewController` isn't updated within the test target,
     we're book keeping it here for the purpose of testing the presented view
     controller is what we expect.
     */

    private(set) var test_presentedViewController: UIViewController?

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        test_presentedViewController = viewControllerToPresent
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    #endif
}

// MARK: - UINavigationControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension DocumentFileUploadViewController: UINavigationControllerDelegate {
    // Conformance is required for UIImagePickerController
}

// MARK: - UIImagePickerControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension DocumentFileUploadViewController: UIImagePickerControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        defer {
            currentlySelectingSide = nil
        }

        guard let side = currentlySelectingSide,
              let image = info[.originalImage] as? UIImage
        else {
            // TODO(IDPROD-2816): log error
            return picker.dismiss(animated: true, completion: nil)
        }

        upload(
            image: image,
            for: side,
            method: (picker.sourceType == .camera) ? .manualCapture : .fileUpload
        )
        updateUI()
        picker.dismiss(animated: true) { [weak self] in
            // Set focus back onto the list item after the picker is dismissed
            self?.focusAccessibilityOnListItem(for: side)
        }
    }
}

// MARK: - UIDocumentPickerDelegate

@available(iOSApplicationExtension, unavailable)
extension DocumentFileUploadViewController: UIDocumentPickerDelegate {
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        defer {
            currentlySelectingSide = nil
        }

        guard let side = currentlySelectingSide,
              let url = urls.first else {
            // TODO(IDPROD-2816): log error
            return
        }

        setIsLoadingImageFromFile(true, for: side)
        imageLoadingQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else {
                    // TODO(IDPROD-2816): log error
                    return
                }
                self.upload(image: image, for: side, method: .fileUpload)
            } catch {
                // TODO(IDPROD-2816): log error
            }
            self.setIsLoadingImageFromFile(false, for: side)
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
        }

        // Update UI to show spinner
        updateUI()
        // Set focus back onto the list item after the picker is dismissed
        focusAccessibilityOnListItem(for: side)
    }
}

// MARK: - DocumentUploaderDelegate

@available(iOSApplicationExtension, unavailable)
extension DocumentFileUploadViewController: DocumentUploaderDelegate {
    func documentUploaderDidUpdateStatus(_ documentUploader: DocumentUploader) {
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
        }
    }
}
