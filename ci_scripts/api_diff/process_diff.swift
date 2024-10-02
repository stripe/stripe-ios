#!/usr/bin/env swift

import Foundation
import SwiftSyntax
import SwiftSemantics
import SwiftSyntaxParser

// Ensure we have the correct number of arguments
guard CommandLine.arguments.count == 3 else {
    print("Usage: process_diff.swift old_file.swiftinterface new_file.swiftinterface")
    exit(1)
}

let oldFilePath = CommandLine.arguments[1]
let newFilePath = CommandLine.arguments[2]

// Function to parse declarations from a Swift interface file
func parseDeclarations(from filePath: String) throws -> Set<String> {
    let sourceFile = try SyntaxParser.parse(URL(fileURLWithPath: filePath))
    let collector = DeclarationCollector()
    collector.walk(sourceFile)
    let declarations = collector.declarations.map { $0.description.trimmingCharacters(in: .whitespacesAndNewlines) }
    return Set(declarations)
}

do {
    // Parse declarations from both files
    let oldDeclarations = try parseDeclarations(from: oldFilePath)
    let newDeclarations = try parseDeclarations(from: newFilePath)
    
    // Find added and removed declarations
    let removedDeclarations = oldDeclarations.subtracting(newDeclarations)
    let addedDeclarations = newDeclarations.subtracting(oldDeclarations)
    
    var diffOutput = ""
    
    // Format the output similar to a diff
    if !removedDeclarations.isEmpty || !addedDeclarations.isEmpty {
        for decl in removedDeclarations.sorted() {
            diffOutput += "- \(decl)\n"
        }
        for decl in addedDeclarations.sorted() {
            diffOutput += "+ \(decl)\n"
        }
    }
    
    // Print the diff output
    print(diffOutput)
} catch {
    print("Error parsing files: \(error)")
    exit(1)
}
