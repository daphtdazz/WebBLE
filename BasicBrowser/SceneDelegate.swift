//
//  SceneDelegate.swift
//  WebBLE
//
//  Copyright © 2026 David Park. All rights reserved.
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

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if !connectionOptions.urlContexts.isEmpty {
            handleURLContexts(connectionOptions.urlContexts)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Called from external link with scheme webble (in that case there will just be one).
        handleURLContexts(URLContexts)
    }

    private func handleURLContexts(_ contexts: Set<UIOpenURLContext>) {
        guard
            let url = contexts.first?.url,
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else { return }
        components.scheme = "https"
        guard let httpsURL = components.url else {
            NSLog("URL not convertible to https url")
            return
        }
        guard let vc = viewController else {
            NSLog("Error opening URL \(httpsURL): viewController not instantiated")
            return
        }
        vc.loadURL(httpsURL)
    }

    private var viewController: ViewController? {
        guard
            let nc = window?.rootViewController as? UINavigationController,
            let vc = nc.topViewController as? ViewController
        else { return nil }
        return vc
    }
}
