//
//  String+Dict.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 10/10/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation

extension String {
    /**
     - parameters:
         - format: The string to be formatted.
         - arguments: A dictionary containing the which keys should be replaced by which values.
     - returns: A formatted string

     Parses a format string using a dictionary of arguments

     Replaces occurrences of `"${key}"` with their respective values.

     ```
     String(format: "Hello, ${user}", ["user": "Flavio"]) // Hello, Flavio
     ```
     */
    init(format: String, arguments: [String: CustomStringConvertible]) {
        self.init(describing: arguments.reduce(format)
        { (format: String, args: (key: String, value: CustomStringConvertible)) -> String in
            format.replacingOccurrences(of: "${\(args.key)}", with: args.value.description)
        })
    }
}
