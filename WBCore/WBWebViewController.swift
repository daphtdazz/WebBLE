//
//  WBWebViewContainerController.swift
//  WebBLE
//
//  Created by David Park on 23/09/2019.
//

import UIKit
import WebKit

protocol ConsoleToggler {
    func toggleConsole()
}

class WBAlertAction: UIAlertAction {
    var alertController: UIAlertController!
}

@objc protocol WBWebViewControllerDelegate {
    func canDownload(from host: String) async -> Bool
    @objc optional func didNavigateTo(_ url: URL)
    var downloadDirectory: URL? { get }
}

class WBWebViewController:
    UIViewController, WKNavigationDelegate, WKUIDelegate, WBPicker, WKDownloadDelegate,
    WKScriptMessageHandlerWithReply, WKScriptMessageHandler
{

    @IBOutlet var loadingProgressContainer: UIView!
    @IBOutlet var loadingProgressView: UIView!
    @IBOutlet var webView: WBWebView!
    let webViewRefreshControl = UIRefreshControl()

    var wbManagersByRealmId: [String: WBManager] = [:]
    var currentWBManager: WBManager?
    var delegate: WBWebViewControllerDelegate!

    let logManager = WBLogManager()

    // If the pop up picker is showing, then the
    // following two vars are not null.
    @objc var pickerIsShowing = false
    var popUpPickerController: WBPopUpPickerController!
    var popUpPickerBottomConstraint: NSLayoutConstraint!

    // MARK: - IBActions
    @IBAction public func toggleConsole() {
        if let consoleToggler = self.parent as? ConsoleToggler {
            consoleToggler.toggleConsole()
        }
    }

    // MARK: - View Event handling
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.configuration.userContentController.add(self, name: "logger")
        webView.scrollView.refreshControl = webViewRefreshControl
        webViewRefreshControl.addTarget(
            self,
            action: #selector(_handlePullToRefresh),
            for: .valueChanged
        )

        for path in ["estimatedProgress"] {
            webView.addObserver(self, forKeyPath: path, options: .new, context: nil)
        }

        webView.configuration.userContentController.addScriptMessageHandler(
            self as WKScriptMessageHandlerWithReply,
            contentWorld: .page,
            name: "bluetooth"
        )
    }
    // MARK: - WBPicker
    public func showPicker(_ manager: WBManager) {
        self.performSegue(withIdentifier: "ShowDevicePicker", sender: manager)
    }
    public func updatePicker() {
        if self.pickerIsShowing {
            self.popUpPickerController.pickerView.reloadAllComponents()
        }
    }

    // MARK: - WKScriptMessageHandler
    open func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        var log: WBLog

        switch message.name {
        case "logger":
            switch message.body {
            case let bodyDict as [String: Any]:
                guard
                    let levelString = bodyDict["level"] as? String,
                    let level = WBLog.Level(rawValue: levelString),
                    let message = bodyDict["message"] as? String
                        else {
                    NSLog("Badly formed dictionary \(bodyDict.description) passed to the logger")
                    return
                }
                log = WBLog(level: level, message: message, args: [])
            case let bodyString as String:
                log = WBLog(level: .log, message: bodyString, args: [])
            default:
                log = WBLog(
                    level: .warn,
                    message: "Unexpected message type from console log: \(message.body)",
                    args: []
                )
            }
            logManager.addLog(log)
        default:
            NSLog("Unexpected handler called \(message.name)")
            return

        }
    }

    // MARK: - WKScriptMessageHandlerWithReply
    open func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
    ) async -> (Any?, String?) {
        switch message.name {
        case "bluetooth":
            guard
                let body = message.body as? [String: Any],
                let realmID = body["realmID"] as? String
            else {
                return (nil, "Badly formed body (should be a dictionary with a realm ID)")
            }
            let wbManager = _ensureManagerFor(realmID)
            return await withCheckedContinuation(
                function: "Pass web bluetooth request to manager"
            ) {
                continuation in
                wbManager.handle(wkMessage: message, replyHandler: {
                    response, message in
                    continuation.resume(returning: (response, message))
                })
            }
        default:
            NSLog("Unexpected handler called \(message.name)")
            return (nil, "Unexpected handler called \(message.name)")
        }
    }

    // MARK: - WKNavigationDelegate
    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        NSLog("start provisional navigation to \(webView.url?.absoluteString ?? "<unknown>")")
        if self.pickerIsShowing {
            // navigation (refresh, back, link click etc.) attempted while picker visible, so hide it since the navigation implies the user is no longer interested in picking a device
            self.popUpPickerController.performSegue(withIdentifier: "Cancel", sender: nil)
        }
        self.loadingProgressContainer.isHidden = false
        self.logManager.clearLogs()
        currentWBManager?.deactivate()
        currentWBManager = nil
        if let newUrl = webView.url {
            delegate.didNavigateTo?(newUrl)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("finished provisional navigation to \(webView.url?.absoluteString ?? "<unknown>")")
        if let url = webView.url,
            url.absoluteString != "about:blank"
        {
            BUD.lastLocation = url
        }
        _clearLoadingUI()

        Task { await _activateWBManager() }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        self._maybeShowErrorUI(error)
        self._clearLoadingUI()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self._maybeShowErrorUI(error)
        self._clearLoadingUI()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences,
    ) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        guard navigationAction.shouldPerformDownload else {
            return (.allow, preferences)
        }
        let host = navigationAction.sourceFrame.securityOrigin.host
        guard
            await delegate.canDownload(from: host) else {
            NSLog("Downloads not allowed from \(host)")
            return (.cancel, preferences)
        }
        return (.download, preferences)
    }
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async -> WKNavigationResponsePolicy {
        if navigationResponse.canShowMIMEType {
            return .allow
        }
        guard let host = navigationResponse.response.url?.host else {
            NSLog("Unable to download from response with no URL")
            return .cancel
        }
        guard
            await delegate.canDownload(from: host) else {
            NSLog("Downloads not allowed from \(host)")
            return .cancel
        }
        return .download
    }

    func webView(
        _ webView: WKWebView,
        navigationAction: WKNavigationAction,
        didBecome download: WKDownload
    ) {
        NSLog(
            """
            nav action to \(navigationAction.request.url?.absoluteString ?? "<unknown>") \
            became download
            """
        )
        download.delegate = self
    }
    func webView(
        _ webView: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        NSLog(
            """
            nav response to \(navigationResponse.response.url?.absoluteString ?? "<unknown>") \
            became download
            """
        )
        download.delegate = self
    }

    // MARK: - WKDownloadDelegate
    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        NSLog("Deciding destination for \(response.url?.absoluteString ?? "<unknown>")")
        let fm = FileManager.default

        guard let downloadDir = delegate.downloadDirectory else {
            return nil
        }

        let path = {
            let ext = (suggestedFilename as NSString).pathExtension
            let baseName = (suggestedFilename as NSString).deletingPathExtension
            for ii in 0... {
                let name = ii == 0 ? suggestedFilename : "\(baseName)-\(ii).\(ext)"
                let place = downloadDir.appending(path: name)
                if !fm.fileExists(atPath: place.path(percentEncoded: false)) {
                    return place as URL?
                }
            }
            // unreachable...
            return nil as URL?
        }()

        NSLog("downloading to \(path?.absoluteString ?? "<nil>")")
        return path
    }
    func downloadDidFinish(_ download: WKDownload) {
        NSLog("Download \(download) finished")
        NotificationCenter.default.postGeneralNotification(
            "square.and.arrow.down.badge.checkmark", "File downloaded",
        )
    }
    func download(
        _ download: WKDownload,
        didFailWithError error: any Error,
        resumeData: Data?
    ) {
        NSLog("Download \(download) failed with error \(error)")
        NotificationCenter.default.postGeneralNotification(
            "", "File download failed: \(error)", .error
        )
    }

    // MARK: - WKUIDelegate
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: (@escaping () -> Void)
    ) {
        self._presentAlert(
            host: frame.request.url?.host,
            message: message,
            actions: [WBAlertAction(title: "OK", style: .default) { _ in completionHandler() }]
        )
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        self._presentAlert(
            host: frame.request.url?.host,
            message: message,
            actions: [
                WBAlertAction(title: "OK", style: .default) { _ in completionHandler(true) },
                WBAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) },
            ]
        )
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        self._presentAlert(
            host: frame.request.url?.host,
            message: prompt,
            actions: [
                WBAlertAction(
                    title: "OK",
                    style: .default,
                    handler: {
                        completionHandler(
                            ($0 as! WBAlertAction).alertController.textFields?.first?.text
                        )
                    }
                ),
                WBAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: { _ in completionHandler(nil) }
                ),
            ],
            textFieldText: defaultText ?? ""
        )
    }

    // MARK: - Segue handling
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let pupc as WBPopUpPickerController:
            popUpPickerController = pupc
            pupc.wbManager = (sender as! WBManager)
            setValue(true, forKey: "pickerIsShowing")
        case let evc as ErrorViewController:
            let error = sender as! Error
            evc.errorMessage = error.localizedDescription
        default:
            break
        }
    }

    @IBAction func unwindToWVContainerController(sender: UIStoryboardSegue) {
        if let puvc = sender.source as? WBPopUpPickerController {
            self.setValue(false, forKey: "pickerIsShowing")
            self.popUpPickerController = nil
            switch sender.identifier {
            case "Cancel":
                puvc.wbManager.cancelDeviceSearch()
                break
            case "Done":
                puvc.wbManager.selectDeviceAt(puvc.pickerView.selectedRow)
                break
            default:
                NSLog("Unknown unwind segue ignored: \(sender.identifier ?? "<none>")")
            }
        }
    }

    // MARK: - Observe protocol
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard
            let defKeyPath = keyPath,
            let defChange = change
        else {
            NSLog("Unexpected change with either no keyPath or no change dictionary!")
            return
        }
        switch defKeyPath {
        case "estimatedProgress":
            let estimatedProgress = defChange[NSKeyValueChangeKey.newKey] as! Double
            let fwidth = self.loadingProgressContainer.frame.size.width
            let newWidth: CGFloat = CGFloat(estimatedProgress) * fwidth
            if newWidth < self.loadingProgressView.frame.size.width {
                self.loadingProgressView.frame.size.width = newWidth
            } else {
                UIView.animate(
                    withDuration: 0.2,
                    animations: {
                        self.loadingProgressView.frame.size.width = newWidth
                    }
                )
            }
        default:
            NSLog("Unexpected change observed by ViewController: \(defKeyPath)")
        }
    }

    // MARK: - Private
    func _presentAlert(
        host: String?,
        message: String,
        actions: [WBAlertAction],
        textFieldText: String? = nil
    ) {
        let alertController = UIAlertController(
            title: host ?? "<unknown>",
            message: message,
            preferredStyle: .alert
        )
        if let dt = textFieldText {
            alertController.addTextField { $0.text = dt }
        }
        for action in actions {
            action.alertController = alertController
            alertController.addAction(action)
            if alertController.preferredAction == nil {
                alertController.preferredAction = action
            }
        }

        // Resign first responder before presenting to avoid an RTIInputSystemClient
        // session conflict when WKWebView holds an active keyboard session.
        self.webView.endEditing(true)
        self.present(alertController, animated: true)
    }

    private func _maybeShowErrorUI(_ error: Error) {
        let nserror = error as NSError
        if nserror.domain == NSURLErrorDomain
            && nserror.code == NSURLErrorCancelled
        {
            return
        }
        self.performSegue(withIdentifier: "nav-error-segue", sender: error)
    }
    @objc func _handlePullToRefresh() {
        NSLog("Pull to refresh triggered")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        webView.reload()
    }
    private func _clearLoadingUI() {
        self.loadingProgressContainer.isHidden = true
        self.webViewRefreshControl.endRefreshing()
    }
    func _activateWBManager() async {
        do {
            guard let realmID = try await self.webView.evaluateJavaScript(
                """
                uk.co.greenparksoftware.realmID
                """
            ) as? String else {
                NSLog("Could not get realm ID, could not enable bluetooth")
                return
            }

            let manager = _ensureManagerFor(realmID)
            currentWBManager = manager
            await manager.activate()
        } catch let e {
            NSLog("Exception enabling bluetooth in view: \(e)")
            return
        }
    }

    @discardableResult func _ensureManagerFor(_ realmID: String) -> WBManager {
        if let existingManager = wbManagersByRealmId[realmID] {
            return existingManager
        }
        let newManager = WBManager(devicePicker: self, realmID: realmID)
        wbManagersByRealmId[realmID] = newManager
        return newManager
    }
}
