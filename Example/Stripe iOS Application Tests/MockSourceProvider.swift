//
//  MockSourceProvider.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/28/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Stripe

class MockSourceProvider: NSObject, STPSourceProvider {

    var selectedSource: STPSource?
    var sources: [STPSource]? = []
    var didCallRetrieveSources: (() -> ())?
    var didCallAddSource: (STPSource -> ())?
    var didCallSelectSource: (STPSource -> ())?

    /// If set, the appropriate functions will complete with these errors
    var retrieveSourcesError: NSError?
    var addSourceError: NSError?
    var selectSourceError: NSError?

    func retrieveSources(completion: STPSourceCompletionBlock) {
        didCallRetrieveSources?()
        if let e = retrieveSourcesError {
            completion(nil, nil, e)
        }
        else {
            completion(selectedSource, sources, nil)
        }
    }

    func addSource(source: STPSource, completion: STPSourceCompletionBlock) {
        didCallAddSource?(source)
        if let e = addSourceError {
            completion(nil, nil, e)
        }
        else {
            sources?.append(source)
            completion(selectedSource, sources, nil)
        }
    }

    func selectSource(source: STPSource, completion: STPSourceCompletionBlock) {
        didCallSelectSource?(source)
        if let e = selectSourceError {
            completion(nil, nil, e)
        }
        else {
            selectedSource = source
            completion(selectedSource, sources, nil)
        }
    }

}
