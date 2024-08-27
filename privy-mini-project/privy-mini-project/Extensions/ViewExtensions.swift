//
//  ViewExtensions.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 22/08/24.
//

import UIKit

extension UIView {
    static let screenSize = UIScreen.main.bounds.size
    
    func createCircleOverlay(_ diameter: CGFloat) {
        guard let parentView = self.superview else {
            return
        }
        
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
    
    func createRoundedRectOverlayMask(_ size: CGSize) {
        guard let parentView = self.superview else {
            return
        }
        
        let path = UIBezierPath()
        path.move(to: CGPoint.zero)
        path.addLine(to: CGPoint(x: size.width, y: 0))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: .zero)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 1
    }
}
