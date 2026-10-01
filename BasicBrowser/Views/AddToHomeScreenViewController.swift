//
//  AddToHomeScreenViewController.swift
//  BleBrowser
//

import UIKit
import WebKit

let DONE_DISMISS_DELAY = 0.15

/// iOS does not have a way for apps to create arbitrary additional home-screen icons that launch into them.
/// It does have a way to do this however via shortcuts: expose an "Intent" that shortcuts can use then the user
/// can create and parameterize a shortcut and add it to the home screen.
/// Since adding shortcuts to pages to open in WebBLE could be very handy, this panel tries to make it as straight-forward
/// as possible for a user to do that.
class AddToHomeScreenViewController: UIViewController, UIDocumentPickerDelegate {

    // MARK: - Properties
    var webView: WBWebView!  // initialized by segue
    var addWebBLEIconBadge: Bool = false

    // MARK: - IBOutlets
    @IBOutlet var copyLinkBadgeView: CheckmarkBadgeShowingView!
    @IBOutlet var copyLinkButton: UIButton!
    @IBOutlet var copyIconBadgeView: CheckmarkBadgeShowingView!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var addLogoSwitch: UISwitch!
    @IBOutlet var openShortcutsBadgeView: CheckmarkBadgeShowingView!
    @IBOutlet var newShortcutBadgeView: CheckmarkBadgeShowingView!
    @IBOutlet var addToHomeScreenBadgeView: CheckmarkBadgeShowingView!

    var badgeViews: [CheckmarkBadgeShowingView] {
        return [
            copyLinkBadgeView,
            copyIconBadgeView,
            openShortcutsBadgeView,
            newShortcutBadgeView,
            addToHomeScreenBadgeView,
        ]
    }

    // MARK: - IBActions
    @IBAction func dismiss() {
        self.presentingViewController?.dismiss(animated: true)
    }
    @IBAction func done(dwellSeconds: Double = DONE_DISMISS_DELAY) {
        for bv in badgeViews {
            bv.showCheckmark()
        }
        _ = Task {
            try await Task.sleep(for: .seconds(dwellSeconds))
            self.presentingViewController?.dismiss(animated: true)
        }
    }

    @IBAction func copyLink() {
        guard let currentLink = webView?.url else {
            // Not expecting this to happen but be defensive and make a log for debugging
            NSLog("Unable to copy link")
            return
        }
        UIPasteboard.general.string = currentLink.absoluteString
        let originalTitle = self.copyLinkButton.titleLabel?.text ?? "Copy Link"
        self.copyLinkButton.setTitle("Copied!", for: .normal)

        _ = Task {
            try await Task.sleep(
                for: .seconds(
                    CheckmarkBadgeShowingView.DWELL_DURATION
                        + CheckmarkBadgeShowingView.SHOW_DURATION
                )
            )
            self.copyLinkButton.setTitle(originalTitle, for: .normal)
        }
        copyLinkBadgeView.showCheckmark()
    }

    @IBAction func redrawBadge() {
        self._updateIconImage()
    }

    @IBAction func saveIconImage() {
        guard
            let image = self._currentIconImage,
            let pngData = image.pngData()
        else { return }

        let safeName = (self.webView.title ?? "Uknown web page")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let fileName = (safeName.isEmpty ? "webble-icon" : safeName) + ".png"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try pngData.write(to: tempURL, options: .atomic)
        } catch {
            NSLog("Failed to write Home Screen icon image: \(error)")
            return
        }

        let picker = UIDocumentPickerViewController(forExporting: [tempURL])
        picker.delegate = self
        self.present(picker, animated: true)
    }

    // MARK: - UIViewController entrypoints
    override func awakeFromNib() {
        super.awakeFromNib()
        Task {
            do {
                try await self._downloadIcon()
                self._updateIconImage()
            } catch let e {
                NSLog("Error building image \(e)")
            }
        }
    }

    // MARK: - UIDocumentPickerDelegate entrypoints
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt: [URL]
    ) {
        self.copyIconBadgeView.showCheckmark()
    }

    // MARK: - Internals for building the image
    private var _iconImage: UIImage?
    private var _currentIconImage: UIImage?

    private static let iconSize = CGSize(width: 512, height: 512)
    private static let badgeSizeProportion = 0.3
    // Matches the corner radius Apple uses for its own app icons at this size.
    private static let iconCornerRadius: CGFloat = iconSize.width * 0.2237

    func _downloadIcon() async throws {
        let result: Any?
        do {
            try result = await self.webView.evaluateJavaScript(
                "uk.co.greenparksoftware.wbutils.getBestIconURL();"
            )
        } catch let e {
            NSLog("Exception fetching icon URL: \(e)")
            return
        }
        let iconURLq =
            (result as? String).flatMap(URL.init(string:))
        guard let iconURL = iconURLq else {
            NSLog("No favicon found!")
            return
        }

        self._iconImage = await withCheckedContinuation(
            function: "Download \(iconURL.absoluteString)"
        ) {
            continuation in
            URLSession.shared.dataTask(with: iconURL) { data, _, _ in
                guard let data, let image = UIImage(data: data) else {
                    NSLog("Unable to download the icon at \(iconURL.absoluteString)")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }.resume()
        }
    }

    private func _updateIconImage() {
        let size = Self.iconSize
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: Self.iconCornerRadius)
            path.addClip()

            UIColor.white.setFill()
            path.fill()

            if let favicon = self._iconImage {
                favicon.draw(in: rect)
            } else {
                let globeSize = CGSize(width: size.width * 0.5, height: size.height * 0.5)
                let globeRect = CGRect(
                    x: (size.width - globeSize.width) / 2,
                    y: (size.height - globeSize.height) / 2,
                    width: globeSize.width,
                    height: globeSize.height
                )
                UIImage(systemName: "globe")?
                    .withTintColor(.systemGray2, renderingMode: .alwaysOriginal)
                    .draw(in: globeRect)
            }

            if self.addLogoSwitch.isOn, let logo = UIImage(named: "Mini Logo") {
                let inset = size.width * 0.04
                let badgeSize = CGSize(
                    width: size.width * Self.badgeSizeProportion,
                    height: size.height * Self.badgeSizeProportion
                )
                let badgeRect = CGRect(
                    x: size.width - badgeSize.width - inset,
                    y: size.height - badgeSize.height - inset,
                    width: badgeSize.width,
                    height: badgeSize.height
                )
                logo.draw(in: badgeRect)
            }
        }
        self._currentIconImage = image
        self.iconImageView.image = image
    }
}
