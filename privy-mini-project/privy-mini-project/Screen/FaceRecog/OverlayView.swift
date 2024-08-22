//
//  OverlayView.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 22/08/24.
//

import UIKit

class OverlayView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCircle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCircle() {
        backgroundColor = .white

        let circleLayer = CAShapeLayer()
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.blue.cgColor
        circleLayer.lineWidth = 2.0

        let circlePath = UIBezierPath(roundedRect: CGRect(x: frame.width / 2 - 50, y: frame.height / 2 - 50, width: 100, height: 100), cornerRadius: 50)
        circleLayer.path = circlePath.cgPath

        layer.addSublayer(circleLayer)
    }
}
