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
        static let tintColor = UIColor.systemBlue
    }

    // MARK: - Instance Properties

    let imageLoadingQueue = DispatchQueue(label: "com.stripe.identity.document-image-loading")

    let listView = ListView()

    /// The document type selected by the user
    let documentType: DocumentType

    /// If the image must come from a live camera feed
    let requireLiveCapture: Bool

    private(set) var currentlySelectingSide: DocumentUploader.DocumentSide?

    /// If the front image file is loading from the file system
    private(set) var isLoadingFrontImageFile = false
    /// If the back image file is loading from the file system
    private(set) var isLoadingBackImageFile = false

    // MARK: Coordinators
    let documentUploader: DocumentUploaderProtocol
    let cameraPermissionsManager: CameraPermissionsManagerProtocol
    let appSettingsHelper: AppSettingsHelperProtocol

    // MARK: - Computed Properties

    var bodyText: String {
        switch documentType {
        case .passport:
            return STPLocalizedString("Please upload an image of your passport", "Instructions for uploading images of passport")
        case .drivingLicense:
            return STPLocalizedString("Please upload images of the front and back of your driver's license", "Instructions for uploading images of drivers license")
        case .idCard:
            return STPLocalizedString("Please upload images of the front and back of your identity card", "Instructions for uploading images of identity card")
        }
    }

    var frontListItemText: String {
        switch documentType {
        case .passport:
            return STPLocalizedString("Image of passport", "Description of passport image")
        case .drivingLicense:
            return STPLocalizedString("Front of driver's license", "Description of front of driver's license image")
        case .idCard:
            return STPLocalizedString("Front of identity card", "Description of front of identity card image")
        }
    }

    var backListItemText: String? {
        switch documentType {
        case .passport:
            return nil
        case .drivingLicense:
            return STPLocalizedString("Back of driver's license", "Description of back of driver's license image")
        case .idCard:
            return STPLocalizedString("Back of identity card", "Description of back of identity card image")
        }
    }

    var frontListItemAccessory: ListItemView.ViewModel.Accessory {
        // Show activity indicator if we're still loading the file from the file system
        if isLoadingFrontImageFile {
            return .activityIndicator
        }

        switch documentUploader.frontUploadStatus {
        case .notStarted,
             .error:
            // TODO(IDPROD-3114|mludowise): Migrate "Select" localized string to StripeUICore
            return .button(title: "Select") { [weak self] in
                self?.didTapSelect(for: .front)
            }
        case .inProgress:
            return .activityIndicator
        case .complete:
            return .icon(Styling.uploadCompleteIcon, tintColor: Styling.tintColor)
        }
    }

    var backListItemAccessory: ListItemView.ViewModel.Accessory {
        // Show activity indicator if we're still loading the file from the file system
        if isLoadingBackImageFile {
            return .activityIndicator
        }

        switch documentUploader.backUploadStatus {
        case .notStarted,
             .error:
            // TODO(IDPROD-3114|mludowise): Migrate "Select" localized string to StripeUICore
            return .button(title: "Select") { [weak self] in
                self?.didTapSelect(for: .back)
            }
        case .inProgress:
            return .activityIndicator
        case .complete:
            return .icon(Styling.uploadCompleteIcon, tintColor: Styling.tintColor)
        }
    }

    var listViewModel: ListView.ViewModel {
        var items = [
            ListItemView.ViewModel(text: frontListItemText, accessory: frontListItemAccessory)
        ]
        if let backListItemText = backListItemText {
            items.append(.init(text: backListItemText, accessory: backListItemAccessory))
        }

        return .init(items: items)
    }

    var isButtonEnabled: Bool {
        // Button should be enabled if either both front and back uploads are
        // complete, or if the document has no back and front upload is complete

        guard case .complete = documentUploader.frontUploadStatus else {
            return false
        }
        guard documentType.hasBack else {
            return true
        }
        guard case .complete = documentUploader.backUploadStatus else {
            return false
        }
        return true
    }

    // MARK: - Init

    init(
        documentType: DocumentType,
        requireLiveCapture: Bool,
        documentUploader: DocumentUploaderProtocol,
        cameraPermissionsManager: CameraPermissionsManagerProtocol,
        appSettingsHelper: AppSettingsHelperProtocol,
        sheetController: VerificationSheetControllerProtocol
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
        listView.configure(with: listViewModel)

        // TODO(IDPROD-3114|mludowise): Migrate "Continue" localized string to StripeUICore
        configure(
            title: STPLocalizedString("File upload", "Title of identity document file upload screen"),
            backButtonTitle: STPLocalizedString("Upload", "Back button label for the identity document file upload screen"),
            viewModel: .init(
                contentView: listView,
                buttonText: "Continue",
                isButtonEnabled: isButtonEnabled,
                didTapButton: { [weak self] in
                    self?.didTapContinueButton()
                }
            )
        )
    }

    func setIsLoadingImageFromFile(
        _ value: Bool,
        for side: DocumentUploader.DocumentSide
    ) {
        switch side {
        case .front:
            isLoadingFrontImageFile = value
        case .back:
            isLoadingBackImageFile = value
        }
    }

    // MARK: - File selection

    func didTapSelect(for side: DocumentUploader.DocumentSide) {
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

        if !requireLiveCapture {
            alert.addAction(.init(
                title: STPLocalizedString("Photo Library", "When selected in an action sheet, opens the device's photo library"),
                style: .default,
                handler: { [weak self] _ in
                    self?.selectPhotoFromLibrary()
                }
            ))
        }

        alert.addAction(.init(
            title: STPLocalizedString("Take Photo", "When selected in an action sheet, opens the device's camera interface"),
            style: .default,
            handler: { [weak self] _ in
                self?.takePhoto()
            }
        ))

        if !requireLiveCapture {
            alert.addAction(.init(
                title: STPLocalizedString("Choose File", "When selected in an action sheet, opens the device's file system browser"),
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
        for side: DocumentUploader.DocumentSide,
        method: VerificationPageDataDocumentFileData.FileUploadMethod
    ) {
        guard let ciImage = CIImage(image: image) else {
            // TODO(IDPROD-2816): log error
            return
        }

        documentUploader.uploadImages(
            for: side,
            originalImage: ciImage,
            documentBounds: nil,
            method: method
        )
    }

    func showCameraPermissionsAlert() {
        let alert = UIAlertController(
            title: STPLocalizedString("Camera permission", "Title displayed when requesting camera permissions"),
            message: STPLocalizedString("We need permission to use your camera. Please allow camera access in app settings.", "Text displayed when requesting camera permissions"),
            preferredStyle: .alert
        )

        if appSettingsHelper.canOpenAppSettings {
            alert.addAction(.init(
                title: STPLocalizedString("App Settings", "Opens the app's settings in the Settings app"),
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
        sheetController?.saveDocumentFileData(documentUploader: documentUploader, completion: { [weak sheetController] apiContent in
            guard let sheetController = sheetController else {
                return
            }

            sheetController.flowController.transitionToNextScreen(
                apiContent: apiContent,
                sheetController: sheetController
            )
        })
    }
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
            updateUI()
            picker.dismiss(animated: true, completion: nil)
        }

        guard let side = currentlySelectingSide,
              let image = info[.originalImage] as? UIImage else {
            // TODO(IDPROD-2816): log error
            return
        }

        upload(
            image: image,
            for: side,
            method: (picker.sourceType == .camera) ? .manualCapture : .fileUpload
        )
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
    }
}

// MARK: - DocumentUploaderObserver

@available(iOSApplicationExtension, unavailable)
extension DocumentFileUploadViewController: DocumentUploaderDelegate {
    func documentUploaderDidUpdateStatus(_ documentUploader: DocumentUploader) {
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
        }
    }
}
