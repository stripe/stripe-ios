//
//  PaperCheckCaptureElement.swift
//  StripePaymentSheet
//
//  Created by Martin Gordon on 8/7/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

/// Simple text field configuration for basic text input
struct SimpleTextConfiguration: TextFieldElementConfiguration {
    let label: String
    let defaultValue: String?
    let keyboardType: UIKeyboardType
    let autocapitalizationType: UITextAutocapitalizationType
    let isOptional: Bool = false
    
    init(
        label: String, 
        defaultValue: String? = nil,
        keyboardType: UIKeyboardType = .default,
        autocapitalizationType: UITextAutocapitalizationType = .sentences
    ) {
        self.label = label
        self.defaultValue = defaultValue
        self.keyboardType = keyboardType
        self.autocapitalizationType = autocapitalizationType
    }
    
    func validate(text: String, isOptional: Bool) -> TextFieldElement.ValidationState {
        return text.isEmpty && !isOptional ? .invalid(TextFieldElement.Error.empty) : .valid
    }
    
    func keyboardProperties(for text: String) -> TextFieldElement.KeyboardProperties {
        return .init(type: keyboardType, textContentType: nil, autocapitalization: autocapitalizationType)
    }
    
    func makeDisplayText(for text: String) -> NSAttributedString {
        return NSAttributedString(string: text)
    }
    
    func maxLength(for text: String) -> Int {
        return 1000
    }
    
    let disallowedCharacters: CharacterSet = []
    
    var accessibilityLabel: String {
        return label
    }
    
    func accessoryView(for text: String, theme: ElementsAppearance) -> UIView? {
        return nil
    }
    
    func subLabel(text: String) -> String? {
        return nil
    }
    
    let shouldShowClearButton: Bool = true
    let editConfiguration: EditConfiguration = .editable
}

/// A custom element that provides UI for capturing front and back images of a paper check
/// along with description and amount fields
class PaperCheckCaptureElement {
    weak var delegate: ElementDelegate?
    
    let theme: ElementsAppearance
    let imageUpdateCallback: (UIImage?, UIImage?, String?, Double?) -> Void
    let ephemeralKeySecret: String?
    
    var frontImage: UIImage?
    var backImage: UIImage?
    var frontFileId: String?
    var backFileId: String?
    var checkDescription: String = ""
    var checkAmount: Double = 0.0
    
    // Paper check upload state
    var paperCheckId: String?
    var isPaperCheckUploading: Bool = false
    
    // Loading states for uploads
    private var frontImageUploading: Bool = false
    private var backImageUploading: Bool = false
    
    // Check if upload button should be shown (show if both images uploaded)
    private var shouldShowUploadButton: Bool {
        let hasImages = frontFileId != nil && backFileId != nil
        
        print("🔍 Upload button check: hasImages=\(hasImages)")
        print("   frontFileId=\(frontFileId ?? "nil"), backFileId=\(backFileId ?? "nil")")
        
        return hasImages
    }
    
    // Check if upload button should be enabled (require all fields)  
    private var shouldEnableUploadButton: Bool {
        let hasDescription = !checkDescription.isEmpty
        let hasAmount = checkAmount > 0
        
        print("🔍 Upload button enable check: description=\(hasDescription), amount=\(hasAmount)")
        print("   checkDescription='\(checkDescription)', checkAmount=\(checkAmount)")
        
        return hasDescription && hasAmount
    }
    
    fileprivate var imagePickerDelegate: ImagePickerDelegate?
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = theme.sectionSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var imagesSection: UIView = UIView()
    
    private lazy var descriptionField: TextFieldElement = {
        let config = SimpleTextConfiguration(label: "Description", defaultValue: "")
        return TextFieldElement(configuration: config, theme: theme)
    }()
    
    private lazy var amountField: TextFieldElement = {
        let config = SimpleTextConfiguration(
            label: "Amount", 
            defaultValue: "", 
            keyboardType: .decimalPad
        )
        return TextFieldElement(configuration: config, theme: theme)
    }()
    
    init(
        theme: ElementsAppearance,
        previousImages: PaperCheckImages? = nil,
        ephemeralKeySecret: String? = nil,
        imageUpdateCallback: @escaping (UIImage?, UIImage?, String?, Double?) -> Void
    ) {
        self.theme = theme
        self.imageUpdateCallback = imageUpdateCallback
        self.ephemeralKeySecret = ephemeralKeySecret
        
        print("🔑 PaperCheckCaptureElement initialized with ephemeralKeySecret: \(ephemeralKeySecret ?? "nil")")
        
        if let previousImages = previousImages {
            self.frontImage = previousImages.frontImage
            self.backImage = previousImages.backImage
        }
        
        setupView()
        setupBindings()
    }
    
    private func setupView() {
        containerView.subviews.forEach { $0.removeFromSuperview() }
        containerView.addSubview(stackView)
        
        // Create simple sections for the text fields
        let descriptionSection = createTextFieldSection(title: "Description", textField: descriptionField)
        let amountSection = createTextFieldSection(title: "Amount", textField: amountField)
        
        // Create images section
        imagesSection = createImagesCaptureSection()
        
        stackView.arrangedSubviews.forEach { stackView.removeArrangedSubview($0) }
        stackView.addArrangedSubview(imagesSection)
        stackView.addArrangedSubview(descriptionSection)
        stackView.addArrangedSubview(amountSection)
        
        // Add upload button if both files are uploaded
        if shouldShowUploadButton {
            let uploadButtonSection = createUploadButtonSection()
            stackView.addArrangedSubview(uploadButtonSection)
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func createTextFieldSection(title: String, textField: TextFieldElement) -> UIView {
        let sectionView = UIView()
        sectionView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = theme.fonts.sectionHeader
        titleLabel.textColor = theme.colors.bodyText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        sectionView.addSubview(titleLabel)
        sectionView.addSubview(textField.view)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sectionView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor),
            
            textField.view.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            textField.view.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor),
            textField.view.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor),
            textField.view.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor)
        ])
        
        return sectionView
    }
    
    private func setupBindings() {
        descriptionField.delegate = self
        amountField.delegate = self
    }
    
    private func createImagesCaptureSection() -> UIView {
        let section = UIView()
        section.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Check Images"
        titleLabel.font = theme.fonts.sectionHeader
        titleLabel.textColor = theme.colors.bodyText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let imagesStackView = UIStackView()
        imagesStackView.axis = .horizontal
        imagesStackView.distribution = .fillEqually
        imagesStackView.spacing = 16
        imagesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let frontCaptureView = createImageCaptureView(
            title: "Front",
            image: frontImage,
            isUploading: frontImageUploading,
            onTap: { [weak self] in
                self?.presentImagePicker(for: .front)
            }
        )
        
        let backCaptureView = createImageCaptureView(
            title: "Back", 
            image: backImage,
            isUploading: backImageUploading,
            onTap: { [weak self] in
                self?.presentImagePicker(for: .back)
            }
        )
        
        imagesStackView.addArrangedSubview(frontCaptureView)
        imagesStackView.addArrangedSubview(backCaptureView)
        
        section.addSubview(titleLabel)
        section.addSubview(imagesStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: section.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: section.trailingAnchor),
            
            imagesStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            imagesStackView.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            imagesStackView.trailingAnchor.constraint(equalTo: section.trailingAnchor),
            imagesStackView.bottomAnchor.constraint(equalTo: section.bottomAnchor),
            imagesStackView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        return section
    }
    
    private func createImageCaptureView(title: String, image: UIImage?, isUploading: Bool = false, onTap: @escaping () -> Void) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = theme.colors.componentBackground
        imageView.layer.cornerRadius = theme.cornerRadius
        imageView.layer.borderWidth = theme.borderWidth
        imageView.layer.borderColor = theme.colors.border.cgColor
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Clear any existing subviews
        imageView.subviews.forEach { $0.removeFromSuperview() }
        
        if let image = image {
            // Show the uploaded image thumbnail
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            
            // Add a subtle overlay to indicate it's uploaded
            let overlayView = UIView()
            overlayView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
            overlayView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(overlayView)
            
            // Add a checkmark to indicate successful upload
            let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            checkmarkView.tintColor = .systemGreen
            checkmarkView.backgroundColor = .white
            checkmarkView.layer.cornerRadius = 12
            checkmarkView.clipsToBounds = true
            checkmarkView.translatesAutoresizingMaskIntoConstraints = false
            imageView.addSubview(checkmarkView)
            
            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
                overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
                
                checkmarkView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
                checkmarkView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8),
                checkmarkView.widthAnchor.constraint(equalToConstant: 24),
                checkmarkView.heightAnchor.constraint(equalToConstant: 24)
            ])
        } else {
            // Show placeholder with camera icon or loading indicator
            imageView.contentMode = .scaleAspectFit
            let placeholderView = UIView()
            placeholderView.backgroundColor = theme.colors.componentBackground
            
            if isUploading {
                // Show loading indicator
                let activityIndicator = UIActivityIndicatorView(style: .medium)
                activityIndicator.color = theme.colors.primary
                activityIndicator.startAnimating()
                activityIndicator.translatesAutoresizingMaskIntoConstraints = false
                
                placeholderView.addSubview(activityIndicator)
                NSLayoutConstraint.activate([
                    activityIndicator.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
                    activityIndicator.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor)
                ])
            } else {
                // Show camera icon
                let cameraIcon = UIImageView(image: UIImage(systemName: "camera"))
                cameraIcon.tintColor = theme.colors.secondaryText
                cameraIcon.translatesAutoresizingMaskIntoConstraints = false
                
                placeholderView.addSubview(cameraIcon)
                NSLayoutConstraint.activate([
                    cameraIcon.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
                    cameraIcon.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor),
                    cameraIcon.widthAnchor.constraint(equalToConstant: 30),
                    cameraIcon.heightAnchor.constraint(equalToConstant: 24)
                ])
            }
            
            imageView.addSubview(placeholderView)
            placeholderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                placeholderView.topAnchor.constraint(equalTo: imageView.topAnchor),
                placeholderView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
                placeholderView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                placeholderView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
            ])
        }
        
        let button = UIButton()
        let buttonTitle: String = {
            if isUploading {
                return "Uploading..."
            } else if image != nil {
                return "Retake \(title)"
            } else {
                return title
            }
        }()
        button.setTitle(buttonTitle, for: .normal)
        button.isEnabled = !isUploading
        button.setTitleColor(theme.colors.primary, for: .normal)
        button.titleLabel?.font = theme.fonts.caption
        button.backgroundColor = theme.colors.componentBackground
        button.layer.cornerRadius = theme.cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(imageCaptureButtonTapped(_:)), for: .touchUpInside)
        button.tag = title == "Front" ? 0 : 1
        
        container.addSubview(imageView)
        container.addSubview(button)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 84),
            
            button.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return container
    }
    
    @objc private func imageCaptureButtonTapped(_ sender: UIButton) {
        let isFont = sender.tag == 0
        let side: CheckImageSide = isFont ? .front : .back
        
        #if targetEnvironment(simulator)
        // In simulator, directly upload dummy data instead of using image picker
        uploadDummyCheckImage(for: side)
        #else
        // On device, use the image picker to capture real images
        presentImagePicker(for: side)
        #endif
    }
    
    private func presentImagePicker(for side: CheckImageSide) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        
        // Create and retain the delegate
        imagePickerDelegate = ImagePickerDelegate(element: self, side: side)
        picker.delegate = imagePickerDelegate
        
        // Find the presenting view controller
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            var presentingVC = rootViewController
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }
            presentingVC.present(picker, animated: true)
        }
    }
    
    func updateImage(_ image: UIImage, for side: CheckImageSide) {
        // This is called only from the image picker delegate (device only)
        uploadImageToStripe(image, for: side)
    }
    
    private func uploadImageToStripe(_ image: UIImage, for side: CheckImageSide) {
        guard let ephemeralKeySecret = ephemeralKeySecret else {
            print("❌ Cannot upload image: ephemeralKeySecret is nil")
            return
        }
        
        let fileName = side == .front ? "check_front" : "check_back"
        
        // Set loading state and update UI
        switch side {
        case .front:
            frontImageUploading = true
        case .back:
            backImageUploading = true
        }
        
        // Refresh UI to show loading state
        DispatchQueue.main.async {
            self.updateImageSectionOnly()
        }
        
        // Upload the actual captured image (device only)
        STPAPIClient.shared.uploadImage(
            image,
            purpose: "paper_check_scan",
            fileName: fileName,
            ephemeralKeySecret: ephemeralKeySecret
        ) { [weak self] result in
            DispatchQueue.main.async {
                // Clear loading state
                switch side {
                case .front:
                    self?.frontImageUploading = false
                case .back:
                    self?.backImageUploading = false
                }
                
                switch result {
                case .success(let file):
                    switch side {
                    case .front:
                        self?.frontImage = image
                        self?.frontFileId = file.id
                    case .back:
                        self?.backImage = image
                        self?.backFileId = file.id
                    }
                    print("✅ Successfully uploaded \(fileName): \(file.id)")
                    
                    // Update UI and callbacks
                    self?.updateAfterImageCapture()
                case .failure(let error):
                    print("❌ Failed to upload \(fileName): \(error.localizedDescription)")
                    // Update UI to show error state
                    self?.updateImageSectionOnly()
                }
            }
        }
    }
    
    private func uploadDummyCheckImage(for side: CheckImageSide) {
        guard let ephemeralKeySecret = ephemeralKeySecret else {
            print("❌ Cannot upload dummy image: ephemeralKeySecret is nil")
            return
        }
        
        let fileName = side == .front ? "check_front" : "check_back"
        let dummyImage = createDummyCheckImage(for: side)
        
        print("📄 Simulator: Creating and uploading dummy check image for \(side == .front ? "front" : "back")")
        
        // Set loading state and update UI
        switch side {
        case .front:
            frontImageUploading = true
        case .back:
            backImageUploading = true
        }
        
        // Refresh UI to show loading state
        updateImageSectionOnly()
        
        // Upload the dummy image data using real Stripe File API
        STPAPIClient.shared.uploadImage(
            dummyImage,
            purpose: "paper_check_scan",
            fileName: fileName,
            ephemeralKeySecret: ephemeralKeySecret
        ) { [weak self] result in
            DispatchQueue.main.async {
                // Clear loading state
                switch side {
                case .front:
                    self?.frontImageUploading = false
                case .back:
                    self?.backImageUploading = false
                }
                
                switch result {
                case .success(let file):
                    switch side {
                    case .front:
                        self?.frontImage = dummyImage
                        self?.frontFileId = file.id
                    case .back:
                        self?.backImage = dummyImage
                        self?.backFileId = file.id
                    }
                    print("✅ Successfully uploaded dummy \(fileName): \(file.id)")
                    
                    // Update UI and callbacks
                    self?.updateAfterImageCapture()
                case .failure(let error):
                    print("❌ Failed to upload dummy \(fileName): \(error.localizedDescription)")
                    // Update UI to show error state
                    self?.updateImageSectionOnly()
                }
            }
        }
    }
    
    private func updateAfterImageCapture() {
        imageUpdateCallback(frontImage, backImage, checkDescription.isEmpty ? nil : checkDescription, checkAmount > 0 ? checkAmount : nil)
        delegate?.didUpdate(element: self)
        
        // Refresh the UI to show the captured image and potentially add upload button
        DispatchQueue.main.async {
            self.updateImageSectionAndButton()
        }
    }
    
    private func updateImageSectionOnly() {
        // Only update the images section without recreating text fields
        let newImagesSection = createImagesCaptureSection()
        
        // Replace the images section in the stack view
        if let currentImagesSection = stackView.arrangedSubviews.first {
            stackView.removeArrangedSubview(currentImagesSection)
            currentImagesSection.removeFromSuperview()
        }
        
        stackView.insertArrangedSubview(newImagesSection, at: 0)
        imagesSection = newImagesSection
    }
    
    private func updateImageSectionAndButton() {
        // Update images section and potentially add/remove upload button
        updateImageSectionOnly()
        updateUploadButtonVisibility()
    }
    
    private func updateUploadButtonVisibility() {
        // Check if we need to add or remove the upload button
        let currentlyHasUploadButton = stackView.arrangedSubviews.count > 3
        let shouldHaveUploadButton = shouldShowUploadButton
        
        print("📱 Button visibility check: currently=\(currentlyHasUploadButton), should=\(shouldHaveUploadButton)")
        
        if shouldHaveUploadButton && !currentlyHasUploadButton {
            // Add upload button
            print("➕ Adding upload button")
            let uploadButtonSection = createUploadButtonSection()
            stackView.addArrangedSubview(uploadButtonSection)
        } else if !shouldHaveUploadButton && currentlyHasUploadButton {
            // Remove upload button
            print("➖ Removing upload button")
            if let uploadButtonSection = stackView.arrangedSubviews.last {
                stackView.removeArrangedSubview(uploadButtonSection)
                uploadButtonSection.removeFromSuperview()
            }
        } else if shouldHaveUploadButton && currentlyHasUploadButton {
            // Update existing button state
            print("🔄 Updating existing upload button")
            if let uploadButtonSection = stackView.arrangedSubviews.last,
               let uploadButton = uploadButtonSection.subviews.first as? UIButton {
                let isEnabled = shouldEnableUploadButton
                uploadButton.isEnabled = isEnabled
                uploadButton.backgroundColor = isEnabled ? theme.colors.primary : theme.colors.primary.withAlphaComponent(0.5)
                print("🔘 Updated button enabled state: \(isEnabled)")
            }
        }
    }
    
    private func createDummyCheckImage(for side: CheckImageSide) -> UIImage {
        // Create a dummy check image with appropriate size and content
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.white.setFill()
            context.fill(rect)
            
            // Border
            UIColor.black.setStroke()
            let borderRect = rect.insetBy(dx: 2, dy: 2)
            context.cgContext.setLineWidth(2)
            context.cgContext.stroke(borderRect)
            
            // Check content based on side
            let textColor = UIColor.black
            let font = UIFont.systemFont(ofSize: 16, weight: .medium)
            
            if side == .front {
                // Front side content
                let checkText = """
                DUMMY CHECK - FRONT
                Pay to: Test Recipient
                Amount: $123.45
                Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none))
                """
                
                let textRect = CGRect(x: 20, y: 40, width: size.width - 40, height: size.height - 80)
                checkText.draw(in: textRect, withAttributes: [
                    .font: font,
                    .foregroundColor: textColor
                ])
                
                // Add routing and account numbers (dummy)
                let bankInfo = "⑈123456789⑈ 987654321⑈ 0001"
                let bankRect = CGRect(x: 20, y: size.height - 40, width: size.width - 40, height: 20)
                bankInfo.draw(in: bankRect, withAttributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: textColor
                ])
            } else {
                // Back side content
                let endorsementText = """
                DUMMY CHECK - BACK
                
                For Deposit Only
                Account: XXXX-1234
                
                Signature: ____________
                """
                
                let textRect = CGRect(x: 20, y: 40, width: size.width - 40, height: size.height - 80)
                endorsementText.draw(in: textRect, withAttributes: [
                    .font: font,
                    .foregroundColor: textColor
                ])
            }
        }
    }
    
    private func createUploadButtonSection() -> UIView {
        let section = UIView()
        section.translatesAutoresizingMaskIntoConstraints = false
        
        let uploadButton = UIButton(type: .system)
        uploadButton.setTitle("Upload Check", for: .normal)
        
        let isEnabled = shouldEnableUploadButton
        uploadButton.isEnabled = isEnabled
        uploadButton.backgroundColor = isEnabled ? theme.colors.primary : theme.colors.primary.withAlphaComponent(0.5)
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .disabled)
        uploadButton.titleLabel?.font = theme.fonts.subheadlineBold
        uploadButton.layer.cornerRadius = theme.cornerRadius
        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.addTarget(self, action: #selector(uploadCheckButtonTapped), for: .touchUpInside)
        
        print("🔘 Creating upload button - enabled: \(isEnabled)")
        
        section.addSubview(uploadButton)
        
        NSLayoutConstraint.activate([
            uploadButton.topAnchor.constraint(equalTo: section.topAnchor, constant: 16),
            uploadButton.leadingAnchor.constraint(equalTo: section.leadingAnchor),
            uploadButton.trailingAnchor.constraint(equalTo: section.trailingAnchor),
            uploadButton.bottomAnchor.constraint(equalTo: section.bottomAnchor),
            uploadButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return section
    }
    
    @objc private func uploadCheckButtonTapped() {
        uploadPaperCheck()
    }
    
    private func uploadPaperCheck() {
        guard let frontFileId = frontFileId,
              let backFileId = backFileId,
              !checkDescription.isEmpty,
              checkAmount > 0,
              let ephemeralKeySecret = ephemeralKeySecret else {
            print("❌ Missing required data for paper check upload (including ephemeralKeySecret)")
            return
        }
        
        // Set uploading state
        isPaperCheckUploading = true
        updateUploadButtonVisibility() // Update button to show loading state
        delegate?.didUpdate(element: self) // Notify parent that validation state changed
        
        let amountInCents = Int64(checkAmount * 100)
        let params = STPUSPaperCheckCreateParams(
            amount: amountInCents,
            currency: "usd",
            frontImage: frontFileId,
            backImage: backFileId,
            description: checkDescription
        )
        
        print("📄 Creating US Paper Check with front: \(frontFileId), back: \(backFileId), amount: \(amountInCents), description: \(checkDescription)")
        print("🔑 Using ephemeralKeySecret for paper check upload: \(ephemeralKeySecret)")
        
        STPAPIClient.shared.createUSPaperCheck(with: params, ephemeralKeySecret: ephemeralKeySecret) { [weak self] paperCheck, error in
            DispatchQueue.main.async {
                self?.isPaperCheckUploading = false
                
                if let paperCheck = paperCheck {
                    print("✅ Successfully created US Paper Check: \(paperCheck.stripeID)")
                    self?.handlePaperCheckSuccess(paperCheck)
                } else if let error = error as? Error {
                    print("❌ Failed to create US Paper Check: \(error.localizedDescription)")
                    self?.handlePaperCheckError(error)
                }
                
                self?.updateUploadButtonVisibility() // Update button state
                if let s = self {
                    s.delegate?.didUpdate(element: s) // Notify parent that validation state changed
                }
            }
        }
    }
    
    private func handlePaperCheckSuccess(_ paperCheck: STPUSPaperCheck) {
        // Store the paper check ID
        paperCheckId = paperCheck.stripeID
        
        // Update UI to show success state
        print("Paper check created with ID: \(paperCheck.stripeID)")
        print("✅ Paper check ready - Pay button should now be enabled")
        
        // Notify delegate that validation state has changed (paperCheckId is now set)
        // This will enable the Pay button in PaymentSheet
        delegate?.didUpdate(element: self)
    }
    
    private func handlePaperCheckError(_ error: Error) {
        // Handle error - could show an alert or update UI
        print("Error creating paper check: \(error.localizedDescription)")
        
        // Notify delegate that validation state may have changed (still invalid due to error)
        delegate?.didUpdate(element: self)
    }
    
    func clearImagePickerDelegate() {
        imagePickerDelegate = nil
    }
}

enum CheckImageSide {
    case front, back
}

// MARK: - Element conformance
extension PaperCheckCaptureElement: Element {
    var collectsUserInput: Bool { true }
    
    var view: UIView {
        return containerView
    }
    
    var validationState: ElementValidationState {
        // Check if both images are captured, uploaded, required fields are filled, AND paper check is uploaded
        if frontImage != nil && backImage != nil && frontFileId != nil && backFileId != nil && 
           !checkDescription.isEmpty && checkAmount > 0 && paperCheckId != nil && !isPaperCheckUploading {
            return .valid
        } else {
            return .invalid(error: Error.missingRequiredInfo, shouldDisplay: true)
        }
    }
}

// MARK: - ElementDelegate
extension PaperCheckCaptureElement: ElementDelegate {
    func didUpdate(element: Element) {
        if element === descriptionField {
            checkDescription = descriptionField.text
        } else if element === amountField {
            checkAmount = Double(amountField.text) ?? 0.0
        }
        
        imageUpdateCallback(frontImage, backImage, checkDescription.isEmpty ? nil : checkDescription, checkAmount > 0 ? checkAmount : nil)
        delegate?.didUpdate(element: self)
        
        // Check if we need to show/hide the upload button based on updated text fields
        DispatchQueue.main.async {
            self.updateUploadButtonVisibility()
        }
    }
    
    func continueToNextField(element: Element) {
        delegate?.continueToNextField(element: self)
    }
}

// MARK: - Image Picker Delegate
private class ImagePickerDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    weak var element: PaperCheckCaptureElement?
    let side: CheckImageSide
    
    init(element: PaperCheckCaptureElement, side: CheckImageSide) {
        self.element = element
        self.side = side
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            element?.updateImage(image, for: side)
        }
        element?.clearImagePickerDelegate()
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        element?.clearImagePickerDelegate()
        picker.dismiss(animated: true)
    }
}


// MARK: - Error
extension PaperCheckCaptureElement {
    enum Error: ElementValidationError, LocalizedError {
        case missingRequiredInfo
        
        var errorDescription: String? {
            switch self {
            case .missingRequiredInfo:
                return "Please capture both check images, fill in all required fields, and upload the check before proceeding"
            }
        }
        
        var isUnrecoverable: Bool {
            return false
        }
    }
}
