//
//  AccountHolder.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/17/21.
//

import Foundation

public enum AccountHolder {
    public case customer(id: String)
    public case merchant(id: String)
}
