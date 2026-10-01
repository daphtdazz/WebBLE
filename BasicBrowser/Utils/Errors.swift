//
//  Errors.swift
//  WebBLE
//
//  Created by David Park on 21/09/2026.
//

import Foundation

struct WebBLEError: Error, CustomLocalizedStringResourceConvertible {
    let message: String

    var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(stringLiteral: message)
    }
}
