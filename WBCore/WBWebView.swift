//
//  WBWebView.swift
//  BleBrowser
//
//  Created by David Park on 22/12/2016.
//  Copyright 2016-2017 David Park. All rights reserved.
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
import UIKit
import WebKit

class WBWebView: WKWebView, WKNavigationDelegate {
    let webBluetoothHandlerName = "bluetooth"
    private var _wbManager: WBManager?
    var wbManager: WBManager? {
        get {
            return self._wbManager
        }
        set(newWBManager) {
            if self._wbManager != nil {
                self.configuration.userContentController.removeScriptMessageHandler(
                    forName: self.webBluetoothHandlerName,
                    contentWorld: .page
                )
            }
            self._wbManager = newWBManager
            if let newMan = newWBManager {
                self.configuration.userContentController.addScriptMessageHandler(
                    newMan,
                    contentWorld: .page,
                    name: self.webBluetoothHandlerName
                )
            }
        }
    }

    private var _navDelegates: [WKNavigationDelegate] = []

    // MARK: - Initializers
    required public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }

    convenience public required init?(coder: NSCoder) {
        // load polyfill script
        let webCfg = WKWebViewConfiguration()
        let userController = WKUserContentController()
        webCfg.userContentController = userController
        webCfg.allowsInlineMediaPlayback = true

        // Set up the user agent name to include an app specific append rather
        // than just the default WKWebView build number
        // This declares us as WebBLE but also includes the system
        // version so that
        // https://bowser-js.github.io/bowser-online/
        // will think we're Safari
        let shortVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "<no-version>"
        let bundleName = Bundle.main.infoDictionary?["CFBundleName"] ?? "<no-app-name>"
        let shortOSVersion = (
            UIDevice.current.systemVersion.replacingOccurrences(
                of: "(\\d+\\.\\d+)(.\\d+)?$", with: "$1", options: [.regularExpression]
            )
        )
        webCfg.applicationNameForUserAgent = (
            "Version/\(shortOSVersion) "
            + "\(bundleName)/\(shortVersionString) "
            + "(like Safari)"
        )

        self.init(
            frame: CGRect(),
            configuration: webCfg
        )
        self.navigationDelegate = self

        // TODO: this probably should be more controllable.
        // Before configuring the WKWebView, delete caches since
        // it seems a bit arbitrary when this happens otherwise.
        // This from http://stackoverflow.com/a/34376943/5920499
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]) as! Set<String>
        let ds = WKWebsiteDataStore.default()
        ds.removeData(
            ofTypes: websiteDataTypes,
            modifiedSince: NSDate(timeIntervalSince1970: 0) as Date,
            completionHandler:{})

        // Load js
        for jsfilename in [
            "stringview",
            "WBUtils",
            "WBEventTarget",
            "WBBluetoothUUID",
            "WBDevice",
            "WBBluetoothRemoteGATTServer",
            "WBBluetoothRemoteGATTService",
            "WBBluetoothRemoteGATTCharacteristic",
            "WBPolyfill"
        ] {
            guard let filePath = Bundle(for: WBWebView.self).path(forResource: jsfilename, ofType:"js") else {
                NSLog("Failed to find polyfill \(jsfilename)")
                return
            }
            var polyfillScriptContent: String
            do {
                polyfillScriptContent = try NSString(contentsOfFile: filePath, encoding: String.Encoding.utf8.rawValue) as String
            } catch _ {
                NSLog("Error loading polyfil")
                return
            }
            let userScript = WKUserScript(
                source: polyfillScriptContent, injectionTime: .atDocumentStart,
                forMainFrameOnly: false)
            userController.addUserScript(userScript)
        }

        // WKWebView static config
        self.translatesAutoresizingMaskIntoConstraints = false
        self.allowsBackForwardNavigationGestures = true
    }

    // MARK: - API
    open func addNavigationDelegate(_ del: WKNavigationDelegate) {
        self._navDelegates.append(del)
    }
    open func removeNavigationDelegate(_ del: WKNavigationDelegate) {
        self._navDelegates.removeAll(where: {$0.isEqual(del)})
    }

    // MARK: - WKNavigationDelegate
    // Propagates the notification to all the registered delegates
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self._navDelegates.forEach{$0.webView?(webView, didStartProvisionalNavigation: navigation)}
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self._enableBluetoothInView()
        self._navDelegates.forEach{$0.webView?(webView, didFinish: navigation)}
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self._navDelegates.forEach{$0.webView?(webView, didFail: navigation, withError: error)}
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self._navDelegates.forEach{$0.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)}
    }

    // MARK: - Internal
    open func _enableBluetoothInView() {
        self.evaluateJavaScript(
            "window.iOSNativeAPI.enableBluetooth()",
            completionHandler: { _, error in
                if let error_ = error {
                    NSLog("Error enabling bluetooth in view: \(error_)")
                }
            }
        )
    }
}

class SpecialTapRecognizer: UITapGestureRecognizer {
    override func canBePrevented(by: UIGestureRecognizer) -> Bool {
        return false
    }
}
