//
//  ConsoleViewContainerController.swift
//  BleBrowser
//
//  Created by David Park on 06/10/2018.
//

import UIKit

class ConsoleContainerViewController: UIViewController {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var consoleScrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var clearSelectionImageView: UIImageView!
    @IBOutlet var copySuccessIndication: UIImageView!

    private var _wbLogManager: WBLogManager?

    deinit {
        if let lm = self._wbLogManager {
            lm.removeObserver(self, forKeyPath: "aLogIsSelected")
        }
    }
    var consoleScrollViewHeightAtStartOfGesture: CGFloat? = nil
    var wbLogManager: WBLogManager! {
        get {
            return self._wbLogManager
        }
        set(logManager) {
            if let lm = self._wbLogManager {
                lm.removeObserver(self, forKeyPath: "aLogIsSelected")
            }
            logManager.addObserver(
                self,
                forKeyPath: "aLogIsSelected",
                options: [.initial, .new],
                context: nil
            )
            self._wbLogManager = logManager
            for cvc in self.children {
                guard let consVC = cvc as? ConsoleViewController else {
                    continue
                }
                consVC.logManager = logManager
                return
            }
        }
    }

    // MARK: - IBActions
    @IBAction func clearSelection(_ sender: UITapGestureRecognizer) {
        self.wbLogManager.deselectLogs()
    }
    @IBAction func copyLogsToClipboard(_ sender: UITapGestureRecognizer) {
        let gpb = UIPasteboard.general
        let text = self.wbLogManager.selectedLogText()
        gpb.string = text
        FlashAnimation(withView: self.copySuccessIndication).go()
    }

    @IBAction func dividerDrag(_ sender: UIPanGestureRecognizer) {
        let yTranslation = sender.translation(in: sender.view).y
        let gestureState = sender.state
        switch gestureState {
        case .began:
            // this to reset the height if we've had a screen rotation since last height set
            self.consoleScrollViewHeightConstraint.constant =
                self.scrollView.frame.height
            self.consoleScrollViewHeightAtStartOfGesture =
                self.consoleScrollViewHeightConstraint.constant
        case .changed:
            self.consoleScrollViewHeightConstraint.constant =
                (self.consoleScrollViewHeightAtStartOfGesture!
                    - yTranslation)
        case .ended:
            self.consoleScrollViewHeightAtStartOfGesture = nil
            self.consoleScrollViewHeightConstraint.constant = self.scrollView.frame.height
            UserDefaults.standard.setValue(
                self.consoleScrollViewHeightConstraint.constant,
                forKey: ViewController.prefKeys.lastConsoleHeight.rawValue
            )
        default: NSLog("Unexpected gesture state \(gestureState)")
        }
    }

    @IBAction func closeConsole(_ sender: Any) {
        NSLog("closeConsole")
        self.performSegue(withIdentifier: "HideConsoleSegueID", sender: self)
    }

    // MARK: - View Delegate
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self._configureImageView()
        let prevOffset = CGFloat(UserDefaults.standard.float(forKey: "lastYScrollOffset"))
        let contentHeight = self.scrollView.contentSize.height
        if contentHeight > prevOffset {
            self.scrollView.contentOffset.y = prevOffset
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UserDefaults.standard.setValue(
            self.scrollView.contentOffset.y,
            forKey: "lastYScrollOffset"
        )
    }

    // MARK: - KVO
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "aLogIsSelected" {
            self._configureImageView()
        }
    }
    private func _configureImageView() {
        if let lm = self._wbLogManager {
            self.clearSelectionImageView?.alpha = lm.aLogIsSelected ? 1.0 : 0.5
        }
    }
}
