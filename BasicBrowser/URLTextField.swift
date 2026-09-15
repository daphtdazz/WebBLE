//
//  URLTextField.swift
//  WebBLE
//
//  Created by David Park on 08/04/2022.
//

import UIKit

class URLTextField: UITextField {
    var alreadyWasFirstResponder = false
    var superViewConstraints: [NSLayoutConstraint] = []

    override func becomeFirstResponder() -> Bool {
        let answer = super.becomeFirstResponder()
        if !self.alreadyWasFirstResponder {
            self.alreadyWasFirstResponder = true
            self.selectAll(nil)
        }
        return answer
    }
    override func resignFirstResponder() -> Bool {
        let answer = super.resignFirstResponder()
        self.alreadyWasFirstResponder = false
        return answer
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        NSLayoutConstraint.deactivate(self.superViewConstraints)
        self.superViewConstraints = []
    }

    override func didMoveToSuperview() {
        guard let sv = self.superview else { return }
        let leading = self.leadingAnchor.constraint(equalTo: sv.leadingAnchor, constant: 8)
        leading.identifier = "URLTextField.leading"
        let trailing = self.trailingAnchor.constraint(equalTo: sv.trailingAnchor, constant: -8)
        trailing.identifier = "URLTextField.trailing"
        self.superViewConstraints = [leading, trailing]
        NSLayoutConstraint.activate(self.superViewConstraints)
    }
}
