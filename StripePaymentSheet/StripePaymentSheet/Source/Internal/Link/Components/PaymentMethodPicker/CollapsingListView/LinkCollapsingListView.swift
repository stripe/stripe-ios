//
//  LinkCollapsingListView.swift
//  StripePaymentSheet
//
//  Created by Chris Mays on 6/25/25.
//

@_spi(STP) import StripeUICore

import UIKit

class LinkCollapsingListView: UIView {

    struct Constants {
        static let margins = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
    }

    private(set) var collapsable: Bool = true

#if !os(visionOS)
let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
#endif

    private(set) var headerView = LinkCollapsingListView.Header()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            headerView,
            listView,
        ])

        stackView.axis = .vertical
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var listView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
        ])

        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(frame: .zero)
        setup()
    }

    func setup() {
        addAndPinSubview(stackView)

        clipsToBounds = true

        layer.cornerRadius = 16
        layer.borderColor = UIColor.linkBorderDefault.cgColor
        tintColor = .linkIconBrand
        backgroundColor = .linkSurfaceSecondary


        headerView.addTarget(self, action: #selector(onHeaderTapped(_:)), for: .touchUpInside)
        headerView.layer.zPosition = 1

        listView.isHidden = true
        listView.layer.zPosition = 0
    }

    func setExpanded(_ expanded: Bool, animated: Bool) {
        let previouslyExpanded = headerView.isExpanded
        headerView.isExpanded = collapsable ? expanded : true

        // Prevent double header animation
        if headerView.isExpanded {
            // TODO(link): revise layout margin placement and remove conditional
            setNeedsLayout()
            layoutIfNeeded()
        } else {
            headerView.layoutIfNeeded()
        }

        guard let listViewIndex = stackView.arrangedSubviews.firstIndex(of: listView) else { return }
        if headerView.isExpanded {
            stackView.showArrangedSubview(at: listViewIndex, animated: animated)
        } else {
            stackView.hideArrangedSubview(at: listViewIndex, animated: animated)
        }

        if !previouslyExpanded && headerView.isExpanded {
            didExpand()
        }
    }

    func didExpand() {
        // Base blank meant to be overridden
    }

    @objc func onHeaderTapped(_ sender: UIView) {
        guard collapsable || !headerView.isExpanded else { return }
        setExpanded(!headerView.isExpanded, animated: true)
#if !os(visionOS)
        impactFeedbackGenerator.impactOccurred()
#endif
    }

}
