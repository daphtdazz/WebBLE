//
//  WebBLEBetterUserDefaults.swift
//  WebBLE
//
//  Created by David Park on 05/10/2026.
//

import Foundation
import BetterUserDefaults

@BetterUserDefaults
class WebBLEBetterUserDefaults: BetterUserDefaults {
    var lastLocation: URL = {
        let svers = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        as! String
        return URL(string: "https://www.greenparksoftware.co.uk/projects/webble/\(svers)")!
    }()
    var consoleOpen: Bool = false
    var lastConsoleHeight: Float = 1.0
    var lastYScrollOffset: Float = 0.0

    var bookmarks: BetterUserDefaultsArray<BookmarkBUD>
    var bookmarksDefault: UDArrayType = DEFAULT_BOOKMARKS

    var allowedDownloadHosts: BetterUserDefaultsArray<AllowedDownloadHostBUD>
    var allowedDownloadHostsDefault: UDArrayType = []
}

let BUD = WebBLEBetterUserDefaults()
