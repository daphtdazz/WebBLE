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

class ViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate, ConsoleToggler {

    enum prefKeys: String {
        case bookmarks
        case consoleOpen
        case lastConsoleHeight
        case version
    }

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
    @IBOutlet var extraShowBarsView: UIView!

    // MARK: Internal
    var initialURL: URL?
    var lastRefresh: Date?

    var bookmarksManager = BookmarksManager(
        userDefaults: UserDefaults.standard, key: prefKeys.bookmarks.rawValue)

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

    var webViewContainerController: WBWebViewContainerController {
        get {
            return self.children.first(where: {$0 as? WBWebViewContainerController != nil}) as! WBWebViewContainerController
        }
    }
    var webViewController: WBWebViewController {
        get {
            return self.webViewContainerController.webViewController
        }
    }
    var webView: WBWebView {
        get {
            return self.webViewController.webView
        }
    }
    var consoleCVC: ConsoleContainerViewController? {
        get {
            return self.children.first(where: {$0 as? ConsoleContainerViewController != nil}) as? ConsoleContainerViewController
        }
    }

    /** Tracked constraint to aid segue animations  */
    weak var consoleViewBottomConstraint: NSLayoutConstraint? = nil

    // MARK: - API
    // MARK: IBActions
    @IBAction func addBookmark() {
        guard
            let title = self.webView.title,
            let url = self.webView.url,
            url.absoluteString != "about:blank"
        else {
            NSLog("Cannot bookmark \(self.webView.title ?? "<no title>") \(self.webView.url?.absoluteString ?? "<no url>")")
            let uac = UIAlertController(title: "Unable to bookmark", message: "This page cannot be bookmarked as it has an invalid title or URL, or was a failed navigation", preferredStyle: .alert)
            uac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(uac, animated: true, completion: nil)
            return
        }

        self.bookmarksManager.addBookmarks([WBBookmark(title: title, url: url)])
        FlashAnimation(withView: self.tick).go()
    }
    @IBAction func goForward() {
        NSLog("Go forward")
        self.webView.goForward()
    }
    @IBAction func goBackward() {
        NSLog("Go backward")
        self.webView.goBack()
    }
    @IBAction func reload() {
        if self.webView.url != nil {
            if let lastRefresh = self.lastRefresh,
                Date() < lastRefresh + 1 {
                NSLog("Hard reload")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if self.webView.isLoading {
                    self.webView.stopLoading()
                }
                self.webView.reloadFromOrigin()
            } else {
                NSLog("Reload")
                self.webView.reload()
            }
        } else if let textLocation = self.locationTextField?.text {
            NSLog("Reload from location")
            self.loadLocation(textLocation)
        }
        self.lastRefresh = Date()
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

    // MARK: - Home bar indicator control
    override var prefersHomeIndicatorAutoHidden: Bool {
        return !self.shouldShowBars
    }

    // MARK: - Console control
    func addConsoleCVC(_ consoleCVC: ConsoleContainerViewController) {
        self.addChild(consoleCVC)
        self.view!.addSubview(consoleCVC.view!)
        consoleCVC.wbLogManager = self.webViewController.logManager
        UserDefaults.standard.setValue(true, forKey: ViewController.prefKeys.consoleOpen.rawValue)
        NSLog("Console CVC added")
    }
    func removeConsoleCVC() {
        guard let ccvc = self.consoleCVC else {
            NSLog("No Console Container View Controller to remove")
            return
        }
        ccvc.removeFromParent()
        ccvc.view!.removeFromSuperview()
        UserDefaults.standard.setValue(false, forKey: ViewController.prefKeys.consoleOpen.rawValue)
        NSLog("Console CVC removed")
    }

    // MARK: - Segue handling
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let bvc = segue.destination as? BookmarksViewController {
            bvc.bookmarksManager = self.bookmarksManager
        }
    }
    @IBAction func unwindToWBController(sender: UIStoryboardSegue) {
        if let bvc = sender.source as? BookmarksViewController,
           let tv = bvc.view as? UITableView,
           let ip = tv.indexPathForSelectedRow {
            if ip.item >= self.bookmarksManager.bookmarks.count {
                NSLog("Selected bookmark is out of range")
            }
            else {
                self.webView.load(URLRequest(url: self.bookmarksManager.bookmarks[ip.item].url))
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

        let ud = UserDefaults.standard

        // connect view to other objects
        self.locationTextField.delegate = self
        self.webView.addNavigationDelegate(self)
        self.webView.scrollView.delegate = self
        self.webView.scrollView.clipsToBounds = false
        self.webViewContainerController.addObserver(self, forKeyPath: "pickerIsShowing", options: [], context: nil)

        for path in ["canGoBack", "canGoForward"] {
            self.webView.addObserver(self, forKeyPath: path, options: .new, context: nil)
        }

        self.loadPreferences()

        // Load last location
        if let url = initialURL {
            loadURL(url)
        }
        else {
            var lastLocation: String
            if let prefLoc = ud.value(forKey: WBWebViewContainerController.prefKeys.lastLocation.rawValue) as? String {
            lastLocation = prefLoc
            } else {
                let svers = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
                lastLocation = "https://www.greenparksoftware.co.uk/projects/webble/\(svers)"
            }
            self.loadLocation(lastLocation)
        }

        // Maybe re-open console
        if ud.bool(forKey: prefKeys.consoleOpen.rawValue) {
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
        self.webView.load(URLRequest(url: url))
    }
    func setLocationText(_ text: String) {
        self.locationTextField.text = text
        self.locationTextField.sizeToFit()
    }

    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

        if let urlString = webView.url?.absoluteString {
            self.setLocationText(urlString)
        }
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
                CGPoint(x: 0.0, y: 1.0), animated: true
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
                CGPoint(x: 0.0, y: 1.0), animated: true
            )
            return false
        }
        // We basically already are at the top, so this tap means show the bars
        self.shouldShowBars = true
        return true
    }

    // MARK: - Observe protocol
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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
    private func loadPreferences() {

        // Sort out the preferences we have.
        let ud = UserDefaults.standard

        let prefsVersion = ud.integer(forKey: ViewController.prefKeys.version.rawValue)

        var hadPrefs = false
        if let bma = ud.array(forKey: ViewController.prefKeys.bookmarks.rawValue) as? [[String: String]] {
            self.bookmarksManager.mergeInBookmarkDicts(bookmarkDicts: bma)
            hadPrefs = true
        }

        // Merge in any defaults.
        let mb = Bundle.main
        guard let defPlistURL = mb.url(forResource: "Defaults", withExtension: "plist"),
            let defDict = NSDictionary(contentsOf: defPlistURL) else {
                assert(false, "Unexpectedly couldn't find defaults")
                return
        }

        let range = (!hadPrefs ? 0 : prefsVersion + 1) ..< self.currentPrefVersion + 1

        for pref in range {
            guard let vDict = defDict.value(forKey: "\(pref)") as? [String: Any] else {
                continue
            }
            vDict.forEach({
                key, object in
                guard let pKey = ViewController.prefKeys(rawValue: key)
                    else {
                        return
                }

                switch pKey {
                case .bookmarks:
                    guard
                        let bdicts = object as? [[String: String]]
                        else {
                            assert(false, "Unexpectedly couldn't find bookmarks in defaults")
                            return
                    }
                    self.bookmarksManager.mergeInBookmarkDicts(bookmarkDicts: bdicts)
                default:
                    return
                }
            })
        }

        // Set the preferences version to be up to date.
        ud.set(self.currentPrefVersion, forKey: ViewController.prefKeys.version.rawValue)
    }
    func setHidesOnSwipesFromScrollView(_ scrollView: UIScrollView) {
        // Due to an apparent bug this should not be called when the toolbar / navbar are animating up or down as far as possible as that seems to cause a crash
        let yOffset = scrollView.contentOffset.y
        let frameHeight = scrollView.frame.size.height
        let contentHeight = scrollView.contentSize.height
        let nc = self.navigationController!

        if yOffset + frameHeight > (
            contentHeight > self.bottomMarginNotToHideBarsIn
                ? contentHeight - self.bottomMarginNotToHideBarsIn
                : 0
        ) {
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
        let pickerIsShowing = self.webViewContainerController.pickerIsShowing
        let toolBarIsShowing = !self.navigationController!.isToolbarHidden
        self.extraShowBarsView.isHidden = pickerIsShowing || toolBarIsShowing
    }
}
