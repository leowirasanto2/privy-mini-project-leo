//
//  ViewController.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 22/08/24.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var faceRecogBtn: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setTitle("Face recognition", for: .normal)
        $0.addTarget(self, action: #selector(didTapFaceRecog), for: .touchUpInside)
        $0.titleLabel?.textColor = .black
        return $0
    }(UIButton())
    
    private lazy var qrScannerBtn: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setTitle("QR scanner", for: .normal)
        $0.addTarget(self, action: #selector(didTapQRScanner), for: .touchUpInside)
        $0.titleLabel?.textColor = .black
        return $0
    }(UIButton())

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupView()
    }
    
    private func setupView() {
        view.backgroundColor = .white
        
        let stackview = UIStackView(frame: .zero)
        stackview.translatesAutoresizingMaskIntoConstraints = false
        stackview.axis = .vertical
        stackview.distribution = .fillEqually
        stackview.alignment = .center
        stackview.spacing = 16
        
        view.addSubview(stackview)
        NSLayoutConstraint.activate([
            stackview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackview.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        [faceRecogBtn, qrScannerBtn].forEach { stackview.addArrangedSubview($0) }
    }

    @objc
    private func didTapFaceRecog(_ sender: Any) {
        navigationController?.pushViewController(FaceRecogView(), animated: true)
    }
    
    @objc
    private func didTapQRScanner(_ sender: Any) {
        navigationController?.pushViewController(QRScannerView(), animated: true)
    }
}

