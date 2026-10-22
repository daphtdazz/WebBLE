//
//  NotificationView.swift
//  WebBLE
//
//  Created by David Park on 21/10/2026.
//
import UIKit

struct GeneralNotification {
    enum `Type` {
        case info
        case error
    }

    static let name = Notification.Name("WEBBLE_GENERAL_NOTIFICATION")

    let systemImageName: String
    let text: String
    var type: `Type` = .info
}

class NotificationView: UIView {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: UILabel!

    func showNotification(notification: GeneralNotification) {
        imageView.image = UIImage(systemName: notification.systemImageName)
        imageView.tintColor = {
            switch notification.type {
            case .info: .white
            case .error: .red
            }
        }()
        label.text = notification.text
        FlashAnimation(withView: self, lingerDuration: {
            switch notification.type {
            case .info: nil
            case .error: 5.0
            }
        }()).go()
    }

    @objc func notification(_ notification: Notification) {
        guard let genNotification = notification.object as? GeneralNotification else {
            return
        }
        showNotification(notification: genNotification)
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        if #available(iOS 26.0, *) {
            cornerConfiguration = UICornerConfiguration.corners(radius: 20)
        }
        if newSuperview == nil {
            NotificationCenter.default
                .removeObserver(
                    self,
                    name: GeneralNotification.name,
                    object: nil
                )
        }
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(notification),
                name: GeneralNotification.name,
                object: nil
            )
        }
    }
}

extension NotificationCenter {
    func postGeneralNotification(
        _ systemImageName: String,
        _ text: String,
        _ type: GeneralNotification.`Type` = .info
    ) {
        let not = GeneralNotification(systemImageName: systemImageName, text: text, type: type)
        post(name: GeneralNotification.name, object: not)
    }
}
