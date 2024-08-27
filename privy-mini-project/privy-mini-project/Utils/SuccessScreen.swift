//
//  SuccessScreen.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 28/08/24.
//


import UIKit

class SuccessScreen: BaseFullscreenView {
    private let message: String
    private let duration: CGFloat
    
    private lazy var messageLbl: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 20, weight: .semibold)
        return $0
    }(UILabel())
    
    init(message: String, duration: CGFloat) {
        self.message = message
        self.duration = duration
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
        self.modalTransitionStyle = .crossDissolve
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        messageLbl.text = message
        view.backgroundColor = .green
        view.addSubview(messageLbl)
        
        NSLayoutConstraint.activate([
            messageLbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    func start(_ from: UIViewController?, _ completion: (() -> Void)?) {
        from?.present(self, animated: true)
        setupView()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.dismiss(animated: false, completion: completion)
        }
    }
}



