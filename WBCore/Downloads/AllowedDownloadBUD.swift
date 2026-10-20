//
//  AllowedDownloadBUD.swift
//  WebBLE
//
//  Created by David Park on 20/10/2026.
//
import Foundation
import BetterUserDefaults

let EXPIRE_AFTER = TimeInterval(integerLiteral: 30 * 24 * 60 * 60)

@BetterUserDefaults
class AllowedDownloadHostBUD: BetterUserDefaults {
    var host: String = ""
    var firstDownloaded: Date = Date.now
    var lastDownloadedDate: Date = Date.now
}
