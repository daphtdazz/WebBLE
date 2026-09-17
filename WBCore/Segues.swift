//
//  Segues.swift
//  WebBLE
//
//  Created by David Park on 26/09/2019.
//

import UIKit

let DURATION = 0.3

class WBShowPickerSegue: UIStoryboardSegue {
    override func perform() {
        let wvcc = self.source as! WBWebViewContainerController
        let puvc = self.destination as! WBPopUpPickerController
        wvcc.addChild(self.destination)
        wvcc.view.addSubview(self.destination.view)
        let topBotConstraint = wvcc.view.bottomAnchor.constraint(equalTo: puvc.view.topAnchor)
        NSLayoutConstraint.activate([
            wvcc.view.leftAnchor.constraint(equalTo: puvc.view.leftAnchor),
            wvcc.view.rightAnchor.constraint(equalTo: puvc.view.rightAnchor),
            topBotConstraint,
        ])
        // inactive initially... activated in the animation block
        wvcc.popUpPickerBottomConstraint = self.source.view.bottomAnchor.constraint(
            equalTo: self.destination.view.bottomAnchor
        )
        wvcc.view.layoutIfNeeded()
        UIView.animate(
            withDuration: DURATION,
            animations: {
                wvcc.view.removeConstraint(topBotConstraint)
                wvcc.popUpPickerBottomConstraint!.isActive = true
                wvcc.view.layoutIfNeeded()
            }
        )
    }
}

class WBHidePickerSegue: UIStoryboardSegue {
    override func perform() {
        let wvcc = self.destination as! WBWebViewContainerController
        let puvc = self.source as! WBPopUpPickerController
        wvcc.view.removeConstraint(wvcc.popUpPickerBottomConstraint!)
        wvcc.popUpPickerBottomConstraint = nil
        UIView.animate(
            withDuration: DURATION,
            animations: {
                wvcc.view.bottomAnchor.constraint(equalTo: puvc.view.topAnchor).isActive = true
                wvcc.view.layoutIfNeeded()
            },
            completion: {
                _ in
                puvc.removeFromParent()
                puvc.view.removeFromSuperview()
            }
        )
    }
}

class ShowConsoleSegue: UIStoryboardSegue {
    override func perform() {
        let vc = self.source as! ViewController
        let vcv = vc.view!
        let ccvc = self.destination as! ConsoleContainerViewController
        let ccv = ccvc.view!

        vc.addConsoleCVC(ccvc)

        // Configure the height
        let prevHeight = CGFloat(
            UserDefaults.standard.float(forKey: ViewController.prefKeys.lastConsoleHeight.rawValue)
        )
        let heightConstraint =
            ccvc.consoleScrollViewHeightConstraint!
        heightConstraint.constant =
            (prevHeight > 0.0
                ? prevHeight
                : 100.0)

        // Configure the intial constraints
        let topConstraint = ccv.topAnchor.constraint(
            equalTo: vcv.bottomAnchor
        )
        vc.consoleViewBottomConstraint = ccv.bottomAnchor.constraint(
            equalTo: vcv.bottomAnchor
        )
        NSLayoutConstraint.activate([
            // Horizontal
            ccv.leadingAnchor.constraint(
                equalTo: vcv.safeAreaLayoutGuide.leadingAnchor
            ),
            ccv.trailingAnchor.constraint(
                equalTo: vcv.safeAreaLayoutGuide.trailingAnchor
            ),
            // Vertical
            //
            // Start by pinning the console at the bottom of the screen,
            // then move it into place with an animation
            // ensure we do not enlarge the console above the url bar,
            // this is something of a hack
            topConstraint,
            ccv.topAnchor.constraint(
                greaterThanOrEqualTo: vcv.safeAreaLayoutGuide.topAnchor,
                constant: 60.0
            ),

            // this constraint will override the existing constraint pinning the bottom of the web view's container to the bottom of the safe area
            ccv.topAnchor.constraint(
                equalTo: vc.webViewContainerController.view.subviews.first!.bottomAnchor
            ),
        ])
        vcv.layoutIfNeeded()

        UIView.animate(
            withDuration: 0.2,
            animations: {
                NSLayoutConstraint.deactivate([topConstraint])
                NSLayoutConstraint.activate([
                    vc.consoleViewBottomConstraint!
                ])
                vcv.layoutIfNeeded()
            }
        )
    }
}

class HideConsoleSegue: UIStoryboardSegue {
    override func perform() {
        let ccvc = self.source
        let ccv = ccvc.view!
        let vc = self.destination as! ViewController
        let vcv = vc.view!

        let topConstraint = ccv.topAnchor.constraint(
            equalTo: vcv.bottomAnchor
        )

        UIView.animate(
            withDuration: 0.2,
            animations: {
                NSLayoutConstraint.deactivate([
                    vc.consoleViewBottomConstraint!
                ])
                NSLayoutConstraint.activate([topConstraint])
                vcv.layoutIfNeeded()
            },
            completion: {
                _ in
                vc.removeConsoleCVC()
            }
        )

    }
}
