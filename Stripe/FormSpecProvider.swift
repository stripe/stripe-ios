//
//  FormSpecProvider.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

// Intentionally force-unwrap since PaymentSheet requires this file to exist
private let formSpecsURL = StripeBundleLocator.resourcesBundle.url(forResource: "form_specs", withExtension: ".json")!

/// Provides FormSpecs for a given a payment method type.
/// - Note: You must `load(completion:)` to load the specs json file into memory before calling `formSpec(for:)`
class FormSpecProvider {
    static var shared: FormSpecProvider = FormSpecProvider()
    fileprivate var formSpecs: [String: FormSpec] = [:]

    /// All loading should take place on this serial queue.
    private lazy var formSpecsUpdateQueue: DispatchQueue = {
        DispatchQueue(label: "com.stripe.Form.FormSpecProvider", qos: .userInitiated)
    }()
    
    /// Loads the JSON form spec into memory
    func load(completion: ((Bool) -> Void)? = nil) {
        formSpecsUpdateQueue.async { [weak self] in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let data = try Data(contentsOf: formSpecsURL)
                let decodedFormSpecs = try decoder.decode([FormSpec].self, from: data)
                self?.formSpecs = Dictionary(uniqueKeysWithValues: decodedFormSpecs.map{ ($0.type, $0) })
                completion?(true)
            } catch {
                completion?(false)
                return
            }
        }
    }
    
    func formSpec(for paymentMethodType: String) -> FormSpec? {
        assert(!formSpecs.isEmpty, "formSpec(for:) was called before loading form specs JSON!")
        return formSpecs[paymentMethodType]
    }
}
