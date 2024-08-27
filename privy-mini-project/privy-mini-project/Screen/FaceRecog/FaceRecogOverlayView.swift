//
//  FaceRecogOverlayView.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 23/08/24.
//

import Foundation
import SwiftUI

class FaceRecogOverlayView: UIView {
    private lazy var titleLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .red
        $0.font = .systemFont(ofSize: 24, weight: .semibold)
        $0.textAlignment = .left
        $0.text = "Verifikasi Wajah"
        return $0
    }(UILabel())
    
    private lazy var previewContainer: UIView = {
        $0.backgroundColor = .gray.withAlphaComponent(0.5)
        $0.layer.cornerRadius = 10
        $0.layer.masksToBounds = true
        return $0
    }(UIView())
    
    private var actionButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .red
        $0.setTitleColor(.white, for: .normal)
        $0.setTitle("Ambil swafoto", for: .normal)
        $0.layer.cornerRadius = 25
        $0.layer.masksToBounds = true
        return $0
    }(UIButton())
    
    private lazy var instructionView: UIView = {
        return createInstructionView()
    }()
    
    private lazy var stepLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textAlignment = .center
        $0.textColor = .white
        $0.backgroundColor = .black.withAlphaComponent(0.5)
        $0.text = "Gelengkan kepala anda ke kanan"
        return $0
    }(UILabel())
    
    private lazy var overlayView: UIView = {
        $0.backgroundColor = .white
        return $0
    }(UIView())
    
    
    init(_ frame: CGRect = .zero) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPreviewContainer() {
        addSubview(previewContainer)
        bringSubviewToFront(previewContainer)
        previewContainer.frame = .init(origin: .zero, size: .init(width: bounds.width * 0.8, height: bounds.width * 0.8))
        previewContainer.center = overlayView.center
    }
    
    private func setupView() {
        backgroundColor = .clear
        overlayView.frame = frame
        addSubview(overlayView)
        overlayView.backgroundColor = .white
        
        [titleLabel, instructionView, actionButton].forEach {
            overlayView.addSubview($0)
        }
        
        setupPreviewContainer()
        
        NSLayoutConstraint.activate([
            titleLabel.bottomAnchor.constraint(equalTo: previewContainer.topAnchor, constant: -16),
            titleLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),

            instructionView.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 16),
            instructionView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            instructionView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            
            actionButton.topAnchor.constraint(equalTo: instructionView.bottomAnchor, constant: 20),
            actionButton.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        setupCircleView()
        setupSquareView()
        setupStepView()
        setupMask()
    }
    
    private func setupCircleView() {
        let circleView = UIView()
        circleView.backgroundColor = .clear
        circleView.frame.size = .init(width: previewContainer.bounds.width * 0.7, height: previewContainer.bounds.width * 0.7)
        let previewCenter = CGPoint(x: previewContainer.frame.midX, y: previewContainer.frame.midY)
        circleView.center = previewContainer.convert(previewCenter, from: circleView)
        let overlayPath = UIBezierPath(rect: frame)
        let circlePath = UIBezierPath(roundedRect: circleView.frame, cornerRadius: circleView.frame.width / 2)
        overlayPath.append(circlePath)
        overlayPath.usesEvenOddFillRule = true
        
        let mask = CAShapeLayer()
        mask.path = overlayPath.cgPath
        mask.fillRule = .evenOdd
        previewContainer.layer.mask = mask
    }
    
    private func setupSquareView() {
        let overlayPath = UIBezierPath(rect: frame)
        let squarePath = UIBezierPath(roundedRect: previewContainer.frame, cornerRadius: 10)
        overlayPath.append(squarePath)
        overlayPath.usesEvenOddFillRule = true
        
        let mask = CAShapeLayer()
        mask.path = overlayPath.cgPath
        mask.fillRule = .evenOdd
        overlayView.layer.mask = mask
    }
    
    private func createInstructionView() -> UIView {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fill
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = 16
        
        let imageContainer = UIView()
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.layer.cornerRadius = 8
        imageContainer.clipsToBounds = true
        imageContainer.heightAnchor.constraint(equalToConstant: 40).isActive = true
        imageContainer.widthAnchor.constraint(equalToConstant: 50).isActive = true
        imageContainer.backgroundColor = .red.withAlphaComponent(0.2)
        
        let image = UIImageView(image: UIImage(systemName: "person.crop.rectangle"))
        image.contentMode = .scaleAspectFill
        image.translatesAutoresizingMaskIntoConstraints = false
        image.tintColor = .red
        imageContainer.addSubview(image)

        NSLayoutConstraint.activate([
            image.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor, constant: 4),
            image.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor, constant: -4),
            image.topAnchor.constraint(equalTo: imageContainer.topAnchor, constant: 4),
            image.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: -4),
        ])
        
        let label = UILabel()
        label.textColor = .black
        label.text = "Sesuaikan wajah dengan garis panduan"
        label.numberOfLines = 2
        [imageContainer, label].forEach {
            stack.addArrangedSubview($0)
        }
        
        return stack
    }
    
    private func setupStepView() {
        previewContainer.addSubview(stepLabel)
        
        NSLayoutConstraint.activate([
            stepLabel.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            stepLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            stepLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            stepLabel.heightAnchor.constraint(equalToConstant: 35),
        ])
    }
    
    private func setupMask() {
        self.layoutIfNeeded()
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = overlayView.bounds
        
        let path = UIBezierPath(rect: overlayView.bounds)
        let rectanglePath = UIBezierPath(rect: previewContainer.frame)
        path.append(rectanglePath)
        path.usesEvenOddFillRule = true
        maskLayer.path = path.cgPath
        
//        overlayView.layer.mask = maskLayer
    }
}

struct UIView_Preview: PreviewProvider {

    static var previews: some View {
        FaceRecogOverlayViewPreview()
    }
}

struct FaceRecogOverlayViewPreview: UIViewRepresentable {
    func makeUIView(context: Context) -> FaceRecogOverlayView {
        let bounds = UIScreen.main.bounds
        return FaceRecogOverlayView(.init(origin: bounds.origin, size: bounds.size))
    }
    
    func updateUIView(_ view: FaceRecogOverlayView, context: Context) {}
}
