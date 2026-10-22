//
//  Copyright © 2017 Paul Theriault & David Park. All rights reserved.
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
import WebKit

class WebBLEViewController:
    UIViewController,
    UITextFieldDelegate,
    UIScrollViewDelegate,
    WBWebViewControllerDelegate,
    WKUIDelegate,
    ConsoleToggler
{

    // MARK: - Properties
    let currentPrefVersion = 1
    let bottomMarginNotToHideBarsIn: CGFloat = 100.0

    // MARK: IBOutlets
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet var tick: UIImageView!
    @IBOutlet var goBackButton: UIBarButtonItem!
    @IBOutlet var goForwardButton: UIBarButtonItem!
    @IBOutlet var refreshButton: UIBarButtonItem!
    @IBOutlet var showConsoleButton: UIBarButtonItem!
    @IBOutlet var addButton: UIBarButtonItem!
    @IBOutlet var extraShowBarsView: UIView!
    @IBOutlet var downloadToolBar: UIBarButtonItem!
    @IBOutlet var downloadMenu: UIMenu!

    // MARK: Internal
    var initialURL: URL?

    weak var addToHomeScreenVC: AddToHomeScreenViewController? = nil

    var shouldShowBars = true {
        didSet {
            let nc = self.navigationController!
            nc.setToolbarHidden(!self.shouldShowBars, animated: true)
            nc.setNavigationBarHidden(!self.shouldShowBars, animated: true)
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
            self._setExtraBarHiddenState()
            self.setHidesOnSwipesFromScrollView(
                self.webView.scrollView
            )
        }
    }
    var webViewController: WBWebViewController {
        return self.children.first(where: { $0 as? WBWebViewController != nil })
            as! WBWebViewController
    }
    var webView: WBWebView {
        return self.webViewController.webView
    }
    var consoleCVC: ConsoleContainerViewController? {
        return self.children.first(where: { $0 as? ConsoleContainerViewController != nil })
            as? ConsoleContainerViewController
    }

    /** Tracked constraint to aid segue animations  */
    weak var consoleViewBottomConstraint: NSLayoutConstraint? = nil

    // MARK: - IBActions
    @IBAction func addBookmark() {
        guard
            let title = self.webView.title,
            let url = self.webView.url,
            url.absoluteString != "about:blank"
        else {
            NSLog(
                """
                Cannot bookmark \(self.webView.title ?? "<no title>") \
                \(self.webView.url?.absoluteString ?? "<no url>")
                """
            )
            let uac = UIAlertController(
                title: "Unable to bookmark",
                message:
                    """
                    This page cannot be bookmarked as it has an invalid title or URL, \
                    or was a failed navigation
                    """,
                preferredStyle: .alert
            )
            uac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(uac, animated: true, completion: nil)
            return
        }

        do {
            let newItem = try BUD.bookmarks.newItem(initial: [:])
            newItem.title = title
            newItem.url = url
        } catch {
            return
        }
        NotificationCenter.default.postGeneralNotification("checkmark", "Bookmark added")
    }
    @IBAction func goForward() {
        NSLog("Go forward")
        self.webView.goForward()
    }
    @IBAction func goBackward() {
        NSLog("Go backward")
        self.webView.goBack()
    }
    @IBAction func refresh() {
        if self.webView.url != nil {
            NSLog("Reload")
            self.webView.reload()
        } else if let textLocation = self.locationTextField?.text {
            NSLog("Reload from location")
            self.loadLocation(textLocation)
        }
    }
    @objc func forceRefresh() {
        if self.webView.url != nil {
            NSLog("Hard reload")
            if self.webView.isLoading {
                self.webView.stopLoading()
            }
            self.webView.reloadFromOrigin()
        } else if let textLocation = self.locationTextField?.text {
            NSLog("Reload from location")
            self.loadLocation(textLocation)
        }
    }
    @IBAction func showBars() {
        NSLog("Show bars")
        self.shouldShowBars = true
    }
    @IBAction func showConsole() {
        guard self.consoleCVC == nil else {
            NSLog("Console already showing")
            return
        }
        NSLog("Show console")
        self.performSegue(
            withIdentifier: "ShowConsoleSegueID",
            sender: self
        )
    }
    @IBAction func toggleConsole() {
        if let cvc = self.consoleCVC {
            cvc.closeConsole(self)
        } else {
            self.showConsole()
        }
    }
    @IBAction func openDownloadsInFiles() {
        DownloadsContainerViewController.openDownloadsInFiles()
    }

    // MARK: - Home bar indicator control
    override var prefersHomeIndicatorAutoHidden: Bool {
        return !self.shouldShowBars
    }

    // MARK: - Console control
    func addConsoleCVC(_ consoleCVC: ConsoleContainerViewController) {
        self.addChild(consoleCVC)
        self.view!.addSubview(consoleCVC.view!)
        consoleCVC.wbLogManager = self.webViewController.logManager
        BUD.consoleOpen = true
        NSLog("Console CVC added")
    }
    func removeConsoleCVC() {
        guard let ccvc = self.consoleCVC else {
            NSLog("No Console Container View Controller to remove")
            return
        }
        ccvc.removeFromParent()
        ccvc.view!.removeFromSuperview()
        BUD.consoleOpen = false
    }

    // MARK: - Segue handling
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let athsvc as AddToHomeScreenViewController:
            athsvc.webView = webView
            self.addToHomeScreenVC = athsvc
        default: break
        }
    }
    @IBAction func unwindToWBController(sender: UIStoryboardSegue) {
        if let bvc = sender.source as? BookmarksViewController,
            let tv = bvc.view as? UITableView,
            let ip = tv.indexPathForSelectedRow
        {
            if ip.item >= BUD.bookmarks.count {
                NSLog("Selected bookmark is out of range")
            } else {
                self.webView.load(URLRequest(url: BUD.bookmarks[ip.item].url))
            }
        }
    }
    @IBAction func unwindConsole(unwindSegue: UIStoryboardSegue) {}

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.loadLocation(textField.text!)
        return true
    }

    // MARK: - Event handling
    override func viewDidLoad() {
        super.viewDidLoad()

        // connect view to other objects
        self.locationTextField.delegate = self
        webViewController.delegate = self
        self.webView.scrollView.delegate = self
        self.webView.scrollView.clipsToBounds = false
        self.webViewController.addObserver(
            self,
            forKeyPath: "pickerIsShowing",
            options: [],
            context: nil
        )

        for path in ["canGoBack", "canGoForward"] {
            self.webView.addObserver(self, forKeyPath: path, options: .new, context: nil)
        }

        self._configureRefreshButton()
        self.downloadToolBar.menu = self.downloadMenu

        // Load last location
        if let url = initialURL {
            loadURL(url)
        } else {
            loadURL(BUD.lastLocation)
        }

        // Maybe re-open console
        if BUD.consoleOpen {
            self.toggleConsole()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let nc = self.navigationController as! NavigationViewController
        nc.addObserver(self, forKeyPath: "navBarIsHidden", options: [.initial, .new], context: nil)
        if self.shouldShowBars {
            self.showBars()
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        let nc = self.navigationController as! NavigationViewController
        nc.removeObserver(self, forKeyPath: "navBarIsHidden")
        super.viewWillDisappear(animated)
    }

    func loadLocation(_ location: String) {
        var location = location
        if !location.hasPrefix("http://") && !location.hasPrefix("https://") {
            location = "https://\(location)"
        }
        guard let url = URL(string: location) else {
            NSLog("Failed to convert location \(location) into a URL")
            return
        }
        loadURL(url)
    }

    func loadURL(_ url: URL) {
        guard self.isViewLoaded else {
            self.initialURL = url
            return
        }
        self.setLocationText(url.absoluteString)
        let sameURL = self.webView.url == url
        if sameURL {
            self.addToHomeScreenVC?.done(dwellSeconds: 0.8)
            return
        }
        self.webView.load(URLRequest(url: url))
        self.addToHomeScreenVC?.dismiss()
    }
    func setLocationText(_ text: String) {
        self.locationTextField.text = text
        self.locationTextField.sizeToFit()
    }

    // MARK: - WBWebViewControllerDelegate
    func canDownload(from host: String) async -> Bool {

        if let allowedHost = BUD.allowedDownloadHosts.first(where: {
            $0.host == host && $0.lastDownloadedDate + EXPIRE_AFTER > Date.now
        }) {
            allowedHost.lastDownloadedDate = Date.now
            return true
        }
        return await withCheckedContinuation(
            function: "Check Can Download From \(host)"
        ) {
            continuation in
            webViewController._presentAlert(
                host: host,
                message: "Allow downloads from here?",
                actions: [
                    WBAlertAction(
                        title: "Yes, allow",
                        style: .default,
                    ) {
                        _ in
                        do {
                            let allowedHost = try BUD.allowedDownloadHosts.newItem(initial: [:])
                            allowedHost.host = host
                            allowedHost.firstDownloaded = Date.now
                            allowedHost.lastDownloadedDate = allowedHost.firstDownloaded
                        } catch let e {
                            NSLog("Could not save the allowed host... \(e.localizedDescription)")
                        }
                        continuation.resume(returning: true)
                    },
                    WBAlertAction(
                        title: "No, not now",
                        style: .cancel,
                    ) { _ in continuation.resume(returning: false) },
                ]
            )
        }

    }
    @objc func didNavigateTo(_ url: URL) {
        self.setLocationText(url.absoluteString)
    }
    var downloadDirectory: URL? {
        let fm = FileManager.default
        let downloadDir = URL.documentsDirectory.appending(path: "Downloads")
        if !fm.fileExists(atPath: downloadDir.path(percentEncoded: false)) {
            do {
                try fm.createDirectory(at: downloadDir, withIntermediateDirectories: true)
            } catch let e {
                NSLog("Failed to create directory at \(downloadDir): \(e)")
                return nil
            }
        }
        return downloadDir
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.setHidesOnSwipesFromScrollView(scrollView)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.setHidesOnSwipesFromScrollView(scrollView)
        if !self.shouldShowBars && scrollView.contentOffset.y == 0.0 {
            // Hack... this *probably* means we've been scrolled to the top using
            // a swipe. This on its own shouldn't show the bars, but at this point
            // it's natural for the user to hit the menu bar to see the menu, but
            // the only way we can detect that is through a scrollToTop delegate
            // method, but we won't get that if we're already at the top. So set
            // a 1 pixel offset so that we can effectively re-enable the
            // scroll to top notification.
            //
            // The only problem with this is that we get *DidEndDecelerating
            // if the user "catches" the swipe scroll and instigates a new
            // swipe scroll. In that case this will erroneously set the 1 pixel
            // offset, leading to a small UI glitch. However that is acceptable
            // given that it would be very unlikely for them to catch it at
            // exactly 0.0 offset.
            scrollView.setContentOffset(
                CGPoint(x: 0.0, y: 1.0),
                animated: true
            )
        }
    }
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if self.shouldShowBars {
            // already showing bars, scroll to top
            return true
        }
        if scrollView.contentOffset.y > 1.0 {
            // big scroll, don't scroll quite to top so that we can detect being
            // told to again and show the status bar
            scrollView.setContentOffset(
                CGPoint(x: 0.0, y: 1.0),
                animated: true
            )
            return false
        }
        // We basically already are at the top, so this tap means show the bars
        self.shouldShowBars = true
        return true
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
        case "canGoBack":
            self.goBackButton.isEnabled = defChange[NSKeyValueChangeKey.newKey] as! Bool
        case "canGoForward":
            self.goForwardButton.isEnabled = defChange[NSKeyValueChangeKey.newKey] as! Bool
        case "navBarIsHidden":
            let navBarIsHidden = defChange[NSKeyValueChangeKey.newKey] as! Bool
            self.shouldShowBars = !navBarIsHidden
        case "pickerIsShowing":
            self._setExtraBarHiddenState()
        default:
            NSLog("Unexpected change observed by ViewController: \(defKeyPath)")
        }
    }

    // MARK: - Private
    private func _configureRefreshButton() {
        // IB doesn't provide a way to add menus to UIBarButtonItems so do it in code
        let frImage = UIImage(systemName: "arrow.clockwise.circle")
        let forceRefreshAction = UIAction(title: "Force Refresh", image: frImage) {
            [weak self] _ in
            self?.forceRefresh()
        }
        refreshButton.menu = UIMenu(title: "", children: [forceRefreshAction])
    }
    func setHidesOnSwipesFromScrollView(_ scrollView: UIScrollView) {
        // Due to an apparent bug this should not be called when the toolbar / navbar
        // are animating up or down as far as possible as that seems to cause a crash
        let yOffset = scrollView.contentOffset.y
        let frameHeight = scrollView.frame.size.height
        let contentHeight = scrollView.contentSize.height
        let nc = self.navigationController!

        if yOffset + frameHeight
            > (contentHeight > self.bottomMarginNotToHideBarsIn
                ? contentHeight - self.bottomMarginNotToHideBarsIn
                : 0)
        {
            if nc.hidesBarsOnSwipe {
                nc.hidesBarsOnSwipe = false
            }
        } else {
            if !nc.hidesBarsOnSwipe {
                nc.hidesBarsOnSwipe = true
            }
        }
    }
    private func _setExtraBarHiddenState() {
        let pickerIsShowing = self.webViewController.pickerIsShowing
        let toolBarIsShowing = !self.navigationController!.isToolbarHidden
        self.extraShowBarsView.isHidden = pickerIsShowing || toolBarIsShowing
    }
}
