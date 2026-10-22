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
    private enum Styling {
        static let spacing: CGFloat = 16
        static let rowSpacing: CGFloat = 8
    }

    weak var delegate: NetworkedIdentityDocumentSelectionViewDelegate?

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = NetworkedIdentityUI.bodyFont
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let rowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Styling.rowSpacing
        return stackView
    }()

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

        stackView.addArrangedSubview(bodyLabel)
        stackView.addArrangedSubview(rowsStackView)
        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        bodyText: String,
        documents: [NetworkedIdentityDocument],
        selectedDocumentID: String?
    ) {
        bodyLabel.text = bodyText
        rowsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for document in documents {
            let isSelected = document.id == selectedDocumentID
            let row = DocumentRow(
                text: NetworkedIdentityFlowViewController.Copy.documentLabel(document),
                isSelected: isSelected,
                onTap: { [weak self] in
                    guard let self else {
                        return
                    }
                    self.delegate?.networkedIdentityDocumentSelectionView(self, didSelect: document)
                }
            )
            rowsStackView.addArrangedSubview(row)
            if isSelected {
                UIAccessibility.post(notification: .layoutChanged, argument: row)
            }
        }
    }
}

/// A saved ID drawn as a bordered card; the border darkens when the ID is selected.
private final class DocumentRow: UIControl {
    private enum Styling {
        static let minHeight: CGFloat = 64
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let insets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        static let unselectedBorderAlpha: CGFloat = 0.15
    }

    private let onTap: () -> Void

    init(text: String, isSelected: Bool, onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)
        self.isSelected = isSelected

        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = NetworkedIdentityUI.bodyFont
        label.textColor = .label
        label.numberOfLines = 0

        let icon = isSelected ? Image.iconCheckmark : Image.iconDocument
        let iconView = UIImageView(image: icon.makeImage(template: true))
        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit
        label.text = text

        let stackView = UIStackView(arrangedSubviews: [label, iconView])
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false
        addAndPinSubview(stackView, insets: Styling.insets)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Styling.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Styling.iconSize),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Styling.minHeight),
        ])

        layer.cornerRadius = Styling.cornerRadius
        layer.borderWidth = 1
        updateBorderColor()

        isAccessibilityElement = true
        accessibilityLabel = text
        accessibilityTraits = isSelected ? [.button, .selected] : .button
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateBorderColor()
    }

    private func updateBorderColor() {
        layer.borderColor = UIColor.label
            .withAlphaComponent(isSelected ? 1 : Styling.unselectedBorderAlpha)
            .resolvedColor(with: traitCollection)
            .cgColor
    }

    @objc private func didTap() {
        onTap()
    }
}
