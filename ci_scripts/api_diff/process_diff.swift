#!/usr/bin/swift

import Foundation
import SwiftSyntax
import SwiftParser

// Ensure we have the correct number of arguments
guard CommandLine.arguments.count == 3 else {
    print("Usage: process_diff.swift old_file.swiftinterface new_file.swiftinterface")
    exit(1)
}

let oldFilePath = CommandLine.arguments[1]
let newFilePath = CommandLine.arguments[2]

// Function to parse declarations from a Swift interface file
func parseDeclarations(from filePath: String) throws -> Set<String> {
    let source = try String(contentsOfFile: filePath)
    let sourceFile = Parser.parse(source: source)
    var declarations = Set<String>()

    class DeclarationCollector: SyntaxAnyVisitor {
        var declarations = Set<String>()

        override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
            if let declNode = node.asProtocol(DeclSyntaxProtocol.self) {
                declarations.insert(declNode.description.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return .visitChildren
        }
    }

    let collector = DeclarationCollector(viewMode: .sourceAccurate)
    collector.walk(sourceFile)
    declarations = collector.declarations
    return declarations
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
