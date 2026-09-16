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

class WBWebViewContainerController: UIViewController, WKNavigationDelegate, WKUIDelegate, WBPicker {

    enum prefKeys: String {
        case lastLocation
    }

    @IBOutlet var loadingProgressContainer: UIView!
    @IBOutlet var loadingProgressView: UIView!

    // At some point it might be nice to try and handle back and
    // forward in the browser better, i.e. by managing multiple managers
    // for recent pages so that you can go back and forward to them
    // without losing bluetooth connections, or at least notifying that
    // the devices have been disconnected
    var wbManager: WBManager?

    var webViewController: WBWebViewController {
        return self.children.first(where: { $0 as? WBWebViewController != nil })
            as! WBWebViewController
    }
    var webView: WBWebView {
        return self.webViewController.webView
    }

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

        self.webView.addNavigationDelegate(self)
        self.webView.uiDelegate = self

        for path in ["estimatedProgress"] {
            self.webView.addObserver(self, forKeyPath: path, options: .new, context: nil)
        }
    }
    // MARK: - WBPicker
    public func showPicker() {
        self.performSegue(withIdentifier: "ShowDevicePicker", sender: self)
    }
    public func updatePicker() {
        if self.pickerIsShowing {
            self.popUpPickerController.pickerView.reloadAllComponents()
        }
    }

    // MARK: - WKNavigationDelegate
    public func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        if self.pickerIsShowing {
            // navigation (refresh, back, link click etc.) attempted while picker visible, so hide it since the navigation implies the user is no longer interested in picking a device
            self.popUpPickerController.performSegue(withIdentifier: "Cancel", sender: nil)
        }
        self.loadingProgressContainer.isHidden = false
        self._configureNewManager()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let urlString = webView.url?.absoluteString,
            urlString != "about:blank"
        {
            UserDefaults.standard.setValue(
                urlString,
                forKey: WBWebViewContainerController.prefKeys.lastLocation.rawValue
            )
        }
        self.loadingProgressContainer.isHidden = true
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        self.loadingProgressContainer.isHidden = true
        self._maybeShowErrorUI(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self._maybeShowErrorUI(error)
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
        case let obj as WBPopUpPickerController:
            self.setValue(true, forKey: "pickerIsShowing")
            self.popUpPickerController = obj
            obj.wbManager = self.wbManager
        case let obj as ErrorViewController:
            let error = sender as! Error
            obj.errorMessage = error.localizedDescription
        default:
            break
        }
    }

    @IBAction func unwindToWVContainerController(sender: UIStoryboardSegue) {
        if let puvc = sender.source as? WBPopUpPickerController {
            self.setValue(false, forKey: "pickerIsShowing")
            puvc.wbManager = nil
            self.popUpPickerController = nil
            switch sender.identifier {
            case "Cancel":
                self.wbManager?.cancelDeviceSearch()
                break
            case "Done":
                self.wbManager?.selectDeviceAt(
                    puvc.pickerView.selectedRow
                )
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
    private func _presentAlert(
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

    private func _configureNewManager() {
        self.wbManager?.clearState()
        self.wbManager = WBManager(devicePicker: self)
        self.webView.wbManager = self.wbManager
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
}
