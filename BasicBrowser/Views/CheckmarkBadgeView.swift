//
//  CheckmarkBadgeView.swift
//  WebBLE
//

import UIKit

fileprivate class _CheckmarkBadgeView: UIView {

    private lazy var circleLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = UIColor.systemGreen.cgColor
        layer.addSublayer(l)
        return l
    }()

    private lazy var tickLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = nil
        l.strokeColor = UIColor.white.cgColor
        l.lineCap = .round
        l.lineJoin = .round
        layer.addSublayer(l)
        return l
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        let side = min(bounds.width, bounds.height)
        let circleRect = CGRect(
            x: (bounds.width - side) / 2,
            y: (bounds.height - side) / 2,
            width: side,
            height: side
        )
        let newCirclePath = UIBezierPath(ovalIn: circleRect).cgPath

        let tickPath = UIBezierPath()
        tickPath.move(to: circleRect.pointAtFraction(x: 0.28, y: 0.52))
        tickPath.addLine(to: circleRect.pointAtFraction(x: 0.44, y: 0.70))
        tickPath.addLine(to: circleRect.pointAtFraction(x: 0.74, y: 0.32))
        let newTickPath = tickPath.cgPath
        let newTickLineWidth = side * 0.1

        applyCurrentAnimationPaths([
            (circleLayer, [("path", newCirclePath)]),
            (tickLayer, [("path", newTickPath), ("lineWidth", newTickLineWidth)]),
        ])

        circleLayer.path = newCirclePath
        tickLayer.path = newTickPath
        tickLayer.lineWidth = newTickLineWidth
    }
}

class CheckmarkBadgeShowingView: UIView {
    static let SHOW_DURATION = 0.1
    static let DWELL_DURATION = 1.5
    static let MINIMIZE_DURATION = 0.5
    static let SHRINK_RATIO = 0.4

    private var _isShowingCheckmark: Bool = false
    private var _widthConstraint: NSLayoutConstraint! = nil
    private var _heightConstraint: NSLayoutConstraint! = nil

    @IBAction func showCheckmark() {
        guard !_isShowingCheckmark else {
            return
        }
        _isShowingCheckmark = true
        let checkView = _CheckmarkBadgeView()
        checkView.translatesAutoresizingMaskIntoConstraints = false
        checkView.alpha = 0.0
        self.addSubview(checkView)

        _widthConstraint = checkView.widthAnchor.constraint(equalToConstant: self.frame.width)
        _heightConstraint = checkView.heightAnchor.constraint(equalToConstant: self.frame.height)
        NSLayoutConstraint.activate([
            self.bottomAnchor.constraint(equalTo: checkView.bottomAnchor),
            self.trailingAnchor.constraint(equalTo: checkView.trailingAnchor),
            _widthConstraint,
            _heightConstraint,
        ])
        self.layoutIfNeeded()
        UIView.animate(
            withDuration: Self.SHOW_DURATION,
            animations: { checkView.alpha = 1.0 }
        )
        _ = Task {
            try await Task.sleep(for: .seconds(Self.SHOW_DURATION + Self.DWELL_DURATION))
            let newSize = Self.SHRINK_RATIO * min(self.frame.size.height, self.frame.size.width)
            UIView.animate(
                withDuration: Self.MINIMIZE_DURATION,
                animations: {
                    self._heightConstraint.constant = newSize
                    self._widthConstraint.constant = newSize
                    self.layoutIfNeeded()
                }
            )
        }
    }
}
