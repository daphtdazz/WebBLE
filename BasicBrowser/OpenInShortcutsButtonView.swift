//
//  OpenInShortcutsButtonView.swift
//  WebBLE
//
//  Created by David Park on 22/09/2026.
//

import AppIntents
import UIKit

class OpenInShortcutsButtonView: UIControl {

    // reference required to work around weirdness in ShortcutsUIButton
    @IBOutlet var widthConstraint: NSLayoutConstraint! = nil

    private var sbv: ShortcutsUIButton! = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        self._initButton()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self._initButton()
    }

    internal override func performPrimaryAction() {
        self.sendActions(for: .primaryActionTriggered)
    }

    private func _initButton() {
        sbv = ShortcutsUIButton(style: .automaticOutline)
        // do the constraints ourselves
        sbv.translatesAutoresizingMaskIntoConstraints = false
        sbv.addTarget(
            self,
            action: #selector(self.performPrimaryAction),
            for: .touchUpInside
        )
        self.addSubview(sbv)

        // Note the additional constraint on our width that is configured in awakeFromNib required
        // to work around the odd behaviour of ShortcutsUIButton
        NSLayoutConstraint.constrainTogether(self, sbv)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // The ShortcutsUIButton works quite weirdly: it adds constraints on its height and width
        // based on the initially calculated size of the view it is in. So in this weird way we have
        // to make sure that we size ourselves to be the right size for it when it does come into
        // existence, else it will make itself too small! So size to fit in a very large box so that
        // it can be as big as it wants.
        self.widthConstraint.constant = sbv.sizeThatFits(CGSize(width: 500, height: 500)).width
    }
}

extension NSLayoutConstraint {
    static func constrainTogether(_ v1: UIView, _ v2: UIView) {
        NSLayoutConstraint.activate([
            v1.topAnchor.constraint(equalTo: v2.topAnchor),
            v1.bottomAnchor.constraint(equalTo: v2.bottomAnchor),
            v1.leadingAnchor.constraint(equalTo: v2.leadingAnchor),
            v1.trailingAnchor.constraint(equalTo: v2.trailingAnchor),
        ])
    }
}
