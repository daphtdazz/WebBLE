//
//  BookmarksManager.swift
//  BleBrowser
//
//  Created by David Park on 03/02/2017.
//  Copyright © 2017 David Park. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

import BetterUserDefaults

@BetterUserDefaults
class BookmarkBUD: BetterUserDefaults {

    var title: String = "<unknown>"
    var url: URL = URL(string: "about:blank")!

    @BetterUserDefaultsIgnore
    var assumedHTTPSURLPath: String {
        get {
            return self.url.absoluteString.replacingOccurrences(of: "https://", with: "")
        }
    }

    static func == (left: BookmarkBUD, right: BookmarkBUD) -> Bool {
        return left.url == right.url
    }
}

let DEFAULT_BOOKMARKS: [UDDictType] = [
    ["title": "Espruino IDE", "url": "https://www.espruino.com/ide"],
    ["title": "Puck.js Start Page", "url": "https://www.puck-js.com/go"],
    ["title": "Pybricks IDE", "url": "https://code.pybricks.com/"],
    ["title": "WebBLE Info", "url": "https://www.greenparksoftware.co.uk/projects/webble/"],
]
