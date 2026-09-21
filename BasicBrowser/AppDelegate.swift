//
//  AppDelegate.swift
//  BasicBrowser
//
//  Created by David Park on 13/01/2017.
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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var _app: UIApplication!

    // MARK: - Code helpers
    func firstWebBLEViewController() -> ViewController? {
        guard
            let scene = _app.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let nc = scene.keyWindow?.rootViewController as? UINavigationController,
            let vc = nc.topViewController as? ViewController
        else {
            return nil
        }
        return vc
    }

    // MARK: - UIApplicationDelegate
    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        self._app = application
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}
