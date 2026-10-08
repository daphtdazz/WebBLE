//
//  Utils.swift
//  PrefMan
//
//  Created by David Park on 12/10/2026.
//
import Foundation

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

import PrefMan
import PrefManMacros


private let testMacros: [String: Macro.Type] = [
    "PrefMan": PrefManMacro.self,
    "PrefManAttr": PrefManAttr.self,
    "PrefManIgnore": PrefManIgnore.self,
]

fileprivate extension String {
    func indent() -> String {
        self
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.count == 0 ? "\n" : "    \($0)\n" }
            .joined(separator: "")
    }
}

func assertPrefManMacroEffect(
    _ input: String,
    _ output: String,
    diagnostics: [DiagnosticSpec] = [],
) {
    assertMacroExpansion(
        """
        @PrefMan
        class MyClass {
        \(input.indent())
        }
        """,
        expandedSource:
            """
            class MyClass {
            \(output.indent())
            }
            """
        ,
        diagnostics: diagnostics,
        macros: testMacros
    )
}

func assertPrefManMacroNoEffect(_ unchangedInput: String) {
    assertPrefManMacroEffect(unchangedInput, unchangedInput)
}

func assertPrefManMacroDiagnostics(_ input: String, _ diagnostics: [DiagnosticSpec]) {
    assertPrefManMacroEffect(
        input,
        input,
        diagnostics: diagnostics
    )
}

extension UserDefaults {
    static func cleanUDForTests() -> UserDefaults {
        let ud = UserDefaults(suiteName: #file)!
        ud.removePersistentDomain(forName: #file)
        return ud
    }
}
