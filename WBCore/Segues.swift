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
        let wvc = self.source as! WBWebViewController
        let puvc = self.destination as! WBPopUpPickerController
        wvc.addChild(self.destination)
        wvc.view.addSubview(self.destination.view)
        let topBotConstraint = wvc.view.bottomAnchor.constraint(equalTo: puvc.view.topAnchor)
        NSLayoutConstraint.activate([
            wvc.view.leftAnchor.constraint(equalTo: puvc.view.leftAnchor),
            wvc.view.rightAnchor.constraint(equalTo: puvc.view.rightAnchor),
            topBotConstraint,
        ])
        // inactive initially... activated in the animation block
        wvc.popUpPickerBottomConstraint = self.source.view.bottomAnchor.constraint(
            equalTo: self.destination.view.bottomAnchor
        )
        wvc.view.layoutIfNeeded()
        UIView.animate(
            withDuration: DURATION,
            animations: {
                wvc.view.removeConstraint(topBotConstraint)
                wvc.popUpPickerBottomConstraint!.isActive = true
                wvc.view.layoutIfNeeded()
            }
        )
    }
}

class WBHidePickerSegue: UIStoryboardSegue {
    override func perform() {
        let wvc = self.destination as! WBWebViewController
        let puvc = self.source as! WBPopUpPickerController
        wvc.view.removeConstraint(wvc.popUpPickerBottomConstraint!)
        wvc.popUpPickerBottomConstraint = nil
        UIView.animate(
            withDuration: DURATION,
            animations: {
                wvc.view.bottomAnchor.constraint(equalTo: puvc.view.topAnchor).isActive = true
                wvc.view.layoutIfNeeded()
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
        let vc = self.source as! WebBLEViewController
        let vcv = vc.view!
        let ccvc = self.destination as! ConsoleContainerViewController
        let ccv = ccvc.view!

        vc.addConsoleCVC(ccvc)

        // Configure the height
        let prevHeight = CGFloat(BUD.lastConsoleHeight)
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
                equalTo: vc.webViewController.view.subviews.first!.bottomAnchor
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
        let vc = self.destination as! WebBLEViewController
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
