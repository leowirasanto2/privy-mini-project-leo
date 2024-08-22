//
//  ViewExtensions.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 22/08/24.
//

import UIKit

extension UIView {
    func createCircleOverlay(_ parentView: UIView, _ diameter: CGFloat) {
        let circleDiameter: CGFloat = diameter
        let circleCenter = CGPoint(x: parentView.bounds.midX, y: parentView.bounds.midY)
        let overlayPath = UIBezierPath(rect: parentView.bounds)
        let circlePath = UIBezierPath(arcCenter: circleCenter, radius: circleDiameter / 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        overlayPath.append(circlePath)
        overlayPath.usesEvenOddFillRule = true
        
        let mask = CAShapeLayer()
        mask.path = overlayPath.cgPath
        mask.fillRule = .evenOdd
        self.layer.mask = mask
    }
}
