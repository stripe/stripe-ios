//
//  HTTPStatusError.swift
//  
//
//  Created by Mel Ludowise on 10/14/24.
//

import Foundation

/// Error passed to the when the `ConnectComponentWebViewController.didFailLoadWithError`
/// when receiving an error status code loading the component web page
struct HTTPStatusError: Error, CustomNSError {
    /// The HTTP status code
    let errorCode: Int
}
