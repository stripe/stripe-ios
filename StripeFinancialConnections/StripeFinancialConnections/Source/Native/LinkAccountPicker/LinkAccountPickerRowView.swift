//
//  LinkAccountPickerRowView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/13/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class LinkAccountPickerRowView: UIView {

    private let didSelect: () -> Void
    private var isSelected: Bool = false {
        didSet {
            layer.cornerRadius = 8
            if isSelected {
                layer.borderColor = UIColor.textBrand.cgColor
                layer.borderWidth = 2
            } else {
                layer.borderColor = UIColor.borderNeutral.cgColor
                layer.borderWidth = 1
            }
        }
    }

    private lazy var institutionIconView: InstitutionIconView = {
        let institutionIconView = InstitutionIconView(size: .small)
        return institutionIconView
    }()
    private lazy var labelRowView: AccountPickerLabelRowView = {
        return AccountPickerLabelRowView()
    }()

    init(
        isDisabled: Bool,
        didSelect: @escaping () -> Void
    ) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        let horizontalStackView = CreateHorizontalStackView(
            arrangedSubviews: [
                institutionIconView,
                labelRowView,
            ]
        )
        if isDisabled {
            horizontalStackView.alpha = 0.25
        }
        addAndPinSubviewToSafeArea(horizontalStackView)

        if !isDisabled {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
            addGestureRecognizer(tapGestureRecognizer)
        }

        isSelected = false  // activate the setter to draw border
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        institutionImageUrl: String?,
        leadingTitle: String,
        trailingTitle: String?,
        subtitle: String?,
        isSelected: Bool
    ) {
        institutionIconView.setImageUrl(institutionImageUrl)
        labelRowView.setLeadingTitle(
            leadingTitle,
            trailingTitle: trailingTitle,
            subtitle: subtitle
        )
        self.isSelected = isSelected
    }

    @objc private func didTapView() {
        self.didSelect()
    }
}

private func CreateInsitutionImageView(imageUrl: String) -> InstitutionIconView {
    let institutionIconView = InstitutionIconView(size: .small)
    institutionIconView.setImageUrl(imageUrl)
    return institutionIconView
}

private func CreateHorizontalStackView(arrangedSubviews: [UIView]) -> UIStackView {
    let horizontalStackView = UIStackView(arrangedSubviews: arrangedSubviews)
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 12,
        leading: 12,
        bottom: 12,
        trailing: 12
    )
    return horizontalStackView
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct LinkAccountPickerRowViewUIViewRepresentable: UIViewRepresentable {

    let institutionImageUrl: String?
    let leadingTitle: String
    let trailingTitle: String?
    let subtitle: String?
    let isSelected: Bool
    let isDisabled: Bool

    func makeUIView(context: Context) -> LinkAccountPickerRowView {
        let view = LinkAccountPickerRowView(
            isDisabled: isDisabled,
            didSelect: {}
        )
        view.configure(
            institutionImageUrl: institutionImageUrl,
            leadingTitle: leadingTitle,
            trailingTitle: trailingTitle,
            subtitle: subtitle,
            isSelected: isSelected
        )
        return view
    }

    func updateUIView(_ uiView: LinkAccountPickerRowView, context: Context) {
        uiView.configure(
            institutionImageUrl: institutionImageUrl,
            leadingTitle: leadingTitle,
            trailingTitle: trailingTitle,
            subtitle: subtitle,
            isSelected: isSelected
        )
    }
}

@available(iOSApplicationExtension, unavailable)
struct LinkAccountPickerRowView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ScrollView {
                VStack(spacing: 10) {
                    VStack(spacing: 2) {
                        Text("Active Accounts")
                        LinkAccountPickerRowViewUIViewRepresentable(
                            institutionImageUrl: nil,
                            leadingTitle: "Joint Checking Very Long Name To Truncate",
                            trailingTitle: "••••6789",
                            subtitle: "$2,000",
                            isSelected: true,
                            isDisabled: false
                        ).frame(height: 60)
                        LinkAccountPickerRowViewUIViewRepresentable(
                            institutionImageUrl: nil,
                            leadingTitle: "Joint Checking",
                            trailingTitle: nil,
                            subtitle: nil,
                            isSelected: false,
                            isDisabled: false
                        ).frame(height: 60)
                        LinkAccountPickerRowViewUIViewRepresentable(
                            institutionImageUrl: nil,
                            leadingTitle: "Joint Checking",
                            trailingTitle: nil,
                            subtitle: "Must be US checking account",
                            isSelected: false,
                            isDisabled: true
                        ).frame(height: 60)
                    }
                }.padding()
            }
        }
    }
}

#endif
