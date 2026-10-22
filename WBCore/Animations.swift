//
//  Animations.swift
//  BleBrowser
//
//  Created by David Park on 16/01/2017.
//  Copyright © 2017 David Park. All rights reserved.
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

import UIKit

struct FlashAnimation {

    let view: UIView

    var fadeInDuration: TimeInterval = 0.05
    var fadeOutDuration: TimeInterval = 0.2
    var lingerDuration: TimeInterval = 1.0

    init(withView view: UIView, lingerDuration: TimeInterval? = nil) {
        self.view = view
        if let linger = lingerDuration {
            self.lingerDuration = linger
        }
    }
    func go() {

        guard let sv = self.view.superview else {
            NSLog("Unable to do flash animation on \(self.view) as it has no superview")
            return
        }

        UIView.transition(with: sv, duration: self.fadeInDuration, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {self.view.isHidden = false}, completion: {
            _ in
            Timer.scheduledTimer(withTimeInterval: self.lingerDuration, repeats: false, block: {
                _ in
                UIView.transition(with: sv, duration: self.fadeOutDuration, options: UIView.AnimationOptions.transitionCrossDissolve, animations: {
                        self.view.isHidden = true
                })
            })
        })
    }
}
