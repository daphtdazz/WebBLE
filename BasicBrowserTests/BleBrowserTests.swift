//
//  BasicBrowserTests.swift
//  BasicBrowserTests
//
//  Copyright 2017 David Park. All rights reserved.
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

import UIKit
import XCTest

class BasicBrowserTests: XCTestCase {
    
    func testUUIDCombine() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        let uuidCombined = uuid1.combineV4(uuid2)

        // check version bits have not changed
        XCTAssertEqual(uuid1.uuid.6 & 0b11000000, uuid2.uuid.6 & 0b11000000)
        XCTAssertEqual(uuid1.uuid.6 & 0b11000000, uuidCombined.uuid.6 & 0b11000000)

        XCTAssertEqual(uuidCombined.combineV4(uuid2), uuid1)
        XCTAssertEqual(uuidCombined.combineV4(uuid1), uuid2)
    }
}
