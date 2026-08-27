//
//  NetworkedIdentityDocumentSelectionView.swift
//  StripeIdentity
//

@_spi(STP) import StripeUICore
import UIKit

protocol NetworkedIdentityDocumentSelectionViewDelegate: AnyObject {
    func networkedIdentityDocumentSelectionView(
        _ view: NetworkedIdentityDocumentSelectionView,
        didSelect document: NetworkedIdentityDocument
    )
}

final class NetworkedIdentityDocumentSelectionView: UIView {
    typealias LabelProvider = (NetworkedIdentityDocument) -> String
    typealias AccessibilityLabelProvider = (NetworkedIdentityDocument, Bool) -> String

    private enum Styling {
        static let spacing: CGFloat = 16
    }

    weak var delegate: NetworkedIdentityDocumentSelectionViewDelegate?

    private(set) var documents: [NetworkedIdentityDocument] = []
    private(set) var selectedDocumentID: String?
    private(set) var isLoading = false
    var accessibilityFocusView: UIView { bodyLabel }

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = IdentityUI.instructionsFont
        label.numberOfLines = 0
        return label
    }()

    private let listView = ListView()
    private let loadingContainer = UIView()
    private let loadingIndicator = ActivityIndicator(size: .medium)

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = Styling.spacing
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        listView.tintColor = IdentityUI.stripeBlurple
        loadingContainer.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: loadingContainer.topAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: loadingContainer.bottomAnchor),
        ])
        loadingContainer.isHidden = true
        stackView.addArrangedSubview(bodyLabel)
        stackView.addArrangedSubview(loadingContainer)
        stackView.addArrangedSubview(listView)
        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        bodyText: String,
        documents: [NetworkedIdentityDocument],
        selectedDocumentID: String?,
        labelProvider: @escaping LabelProvider,
        accessibilityLabelProvider: @escaping AccessibilityLabelProvider
    ) {
        self.documents = documents
        self.selectedDocumentID = selectedDocumentID
        isLoading = false
        bodyLabel.text = bodyText
        loadingIndicator.stopAnimating()
        loadingContainer.isHidden = true
        listView.isHidden = false

        listView.configure(
            with: .init(
                items: documents.map { document in
                    let isSelected = document.id == selectedDocumentID
                    let icon = isSelected ? Image.iconCheckmark : Image.iconDocument
                    return .init(
                        text: labelProvider(document),
                        accessibilityLabel: accessibilityLabelProvider(document, isSelected),
                        accessory: .icon(icon.makeImage(template: true)),
                        onTap: { [weak self] in
                            guard let self else {
                                return
                            }
                            self.delegate?.networkedIdentityDocumentSelectionView(
                                self,
                                didSelect: document
                            )
                        },
                        additionalAccessibilityTraits: isSelected ? .selected : []
                    )
                }
            )
        )
    }

    func configureLoading(bodyText: String) {
        documents = []
        selectedDocumentID = nil
        isLoading = true
        bodyLabel.text = bodyText
        listView.isHidden = true
        loadingContainer.isHidden = false
        loadingIndicator.startAnimating()
    }
}
