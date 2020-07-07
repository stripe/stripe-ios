//
//  PaymentSheetViewController.swift
//  UI Examples
//
//  Created by Yuki Tokuhiro on 7/7/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

import UIKit
import Stripe

class PaymentSheetViewController: UIViewController {
//    var paymentSession: STPPaymentSession? = nil
//    var inProgress: Bool = false {
//        didSet {
//            navigationController?.navigationBar.isUserInteractionEnabled = !inProgress
//            payButton.isEnabled = !inProgress
//            inProgress ? activityIndicatorView.startAnimating() : activityIndicatorView.stopAnimating()
//        }
//    }
//    var selectedIndex: Int = 0
//
//    // UI
//    lazy var activityIndicatorView: UIActivityIndicatorView = {
//        return UIActivityIndicatorView()
//    }()
//    lazy var shadowView: UIView = {
//        let v = UIView()
//        v.backgroundColor = .white
//        v.layer.shadowColor = UIColor.black.cgColor
//        v.layer.shadowOffset = CGSize(width: -5, height: 0)
//        v.layer.shadowOpacity = 0.5
//        v.layer.shadowRadius = 5
//        return v
//    }()
//    lazy var cv: UICollectionView = {
//
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        layout.itemSize = CGSize(width: 114, height: 62)
//        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
//        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        return cv
//    }()
//
//    // Pay buttons
//    lazy var applePayButton: PKPaymentButton = {
//        let b = PKPaymentButton(paymentButtonType: PKPaymentButtonType.buy, paymentButtonStyle: PKPaymentButtonStyle.black)
//        b.addTarget(self, action: #selector(didTapPayButton(sender:)), for: .touchUpInside)
//        b.isHidden = true
//        return b
//    }()
//    lazy var payButton: UIButton = {
//        let button = UIButton(type: .custom)
//        button.layer.cornerRadius = 5
//        button.backgroundColor = .systemBlue
//        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
//        button.setTitle("Pay", for: .normal) // what if I wanted "Pay with X"?
//        button.addTarget(self, action: #selector(didTapPayButton(sender:)), for: .touchUpInside)
//        button.isHidden = true
//        return button
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        title = "Bacs Debit"
//        cv.backgroundColor = .white
//        cv.register((PMCell.self), forCellWithReuseIdentifier: "cell")
//        cv.dataSource = self
//        cv.delegate = self
//        cv.translatesAutoresizingMaskIntoConstraints = false
//        cv.showsHorizontalScrollIndicator = false
//
//        let title = UILabel()
//        title.text = "Payment Methods"
//        title.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
//        title.textColor = .darkGray
//
//        for v in [title, cv, shadowView, applePayButton, payButton, activityIndicatorView] {
//            self.view.addSubview(v)
//            v.translatesAutoresizingMaskIntoConstraints = false
//        }
//
//        let constraints = [
//            cv.heightAnchor.constraint(equalToConstant: 78),
//
//            title.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
//            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//
//            cv.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
//            cv.rightAnchor.constraint(equalTo: view.rightAnchor),
//            cv.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
////            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//            shadowView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 5),
//            shadowView.widthAnchor.constraint(equalToConstant: 5),
//            shadowView.centerYAnchor.constraint(equalTo: cv.centerYAnchor),
//            shadowView.heightAnchor.constraint(equalToConstant: 62),
////            shadowView.topAnchor.constraint(equalTo: cv.topAnchor),
////            shadowView.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
//
//            applePayButton.topAnchor.constraint(equalTo: cv.bottomAnchor, constant: 20),
//            applePayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            applePayButton.widthAnchor.constraint(equalTo: payButton.widthAnchor, multiplier: 1),
//
//            payButton.topAnchor.constraint(equalTo: cv.bottomAnchor, constant: 20),
//            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//        ]
//        NSLayoutConstraint.activate(constraints)
//
//        MyAPIClient.shared().createPaymentIntent(completion: { (result, clientSecret, error) in
//            guard let clientSecret = clientSecret else {
//                self.delegate?.exampleViewController(self, didFinishWithError: error)
//                return
//            }
//
//
//            STPPaymentSession.generatePaymentSession(paymentIntentClientSecret: clientSecret) { session in
//                self.paymentSession = session
//                session!.delegate = self
//                session!.viewControllerToPresentFrom = self
//                self.cv.reloadData()
//            }
//        }, additionalParameters: "country=eu")
//    }
//
//    @objc func didTapPayButton(sender: UIButton) {
//        inProgress = true
//        paymentSession?.pay(completion: { (status, error) in
//            switch status {
//            case .error:
//                self.delegate?.exampleViewController(self, didFinishWithError: error)
//            case .success:
//                self.delegate?.exampleViewController(self, didFinishWithMessage: "Success!")
//            case .userCancellation:
//                break
//            }
//        })
//    }
//}
//
//// MARK: -
//extension BacsDebitExampleViewController: STPPaymentSessionDelegate {
//    func paymentMethodRowsDidUpdate(session: STPPaymentSession) {
//        // I think I want to be able to see which payment method is selected
//        // Change buy button
//        let pm = session.paymentMethodRowAtIndex(index: selectedIndex)
//        print(pm)
//        if pm.paymentMethodType == STPPaymentSession.ApplePayType { // Is this the best I can do to know the selected payment method type? This should be an enum with a .unknown(let rawString) case.
//            applePayButton.isHidden = false
//            payButton.isHidden = true
//        } else {
//            payButton.isHidden = false
//            applePayButton.isHidden = true
//        }
//        self.cv.reloadData() // How to reload only the previous and current selected items?
//
//    }
//
//    func handleEditForRow(index: Int) -> Bool {
//        return false // Set to true to handle it ourselves?
//    }
//
//    func authenticationPresentingViewController() -> UIViewController {
//        self
//    }
//}
//
//extension BacsDebitExampleViewController: UICollectionViewDelegate, UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        // TODO
//        return paymentSession?.numberOfPaymentMethodRows() ?? 0
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PMCell
//        // TODO
//        guard let paymentSession = paymentSession else {
//            return cell
//        }
//        let state = paymentSession.paymentMethodRowAtIndex(index: indexPath.item)
//        cell.configure(icon: state.icon ?? UIImage(), label: state.primaryText, selected: state.isSelected)
//        return cell
//    }
//
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let cell = collectionView.cellForItem(at: indexPath) else {
//            return
//        }
//        collectionView.reloadData() // How to reload only the previous and current selected items?
//        selectedIndex = indexPath.item // Have to set this before `selectPMRowAtIndex`
//        paymentSession?.selectPaymentMethodRowAtIndex(index: indexPath.item) // Do I have to call this? What happens if I don't?
//        // Change pay button
//
//        // Ah I thought I needed to call this myself, but I don't think I do
////        paymentSession!.presentEditControllerForRow(row: paymentSession!.paymentMethodRowAtIndex(index: indexPath.item))
//    }
//}
//
//
//class PMCell: UICollectionViewCell {
//    let icon = UIImageView()
//    let label = UILabel()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        backgroundColor = .white
//        contentView.backgroundColor = .white
//        contentView.alpha = 1
//        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
//        let stack = UIStackView(arrangedSubviews: [icon, label])
//        stack.alignment = .leading
//        stack.spacing = 5
//        stack.axis = .vertical
//        contentView.addSubview(stack)
//        contentView.layer.cornerRadius = 5
//        contentView.layer.borderWidth = 1
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        let constraints = [
////            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
////            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
//
//            stack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 10),
//            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
////            stack.rightAnchor.constraint(equalTo: contentView.rightAnchor),
////            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
////            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ]
//        NSLayoutConstraint.activate(constraints)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func configure(icon: UIImage, label: String, selected: Bool) {
//        self.icon.image = icon
//        self.label.text = label
//        if selected {
//            self.label.textColor = .label
//            self.label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
//            contentView.layer.borderColor = UIColor.darkGray.cgColor
////          tentView.layer.shadowPath
//            layer.backgroundColor = UIColor.clear.cgColor
//            layer.shadowColor = UIColor.black.cgColor
//            layer.shadowOffset = CGSize(width: 0, height: 1.0)
//            layer.shadowOpacity = 0.2
//            layer.shadowRadius = 4.0
////            contentView.layer.masksToBounds = true
//        } else {
////            self.label.textColor = .secondaryLabel
//            self.label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
//
//            contentView.layer.borderColor = UIColor.lightGray.cgColor
//            layer.shadowOpacity = 0.0
//            // TODO change "Card" to "Card ending in 4242" or something?
//        }
//    }
}
