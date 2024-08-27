//
//  FullscreenLoader.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 28/08/24.
//

import UIKit

class FullscreenLoader: BaseFullscreenView {
    private lazy var indicatorBg: UIView? = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 10
        $0.layer.masksToBounds = true
        return $0
    }(UIView())
    
    private lazy var indicator: UIActivityIndicatorView? = {
        $0.hidesWhenStopped = true
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.style = .medium
        $0.tintColor = .white
        return $0
    }(UIActivityIndicatorView())
    
    init() {
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
        guard let indicator = indicator, let indicatorBg = indicatorBg else { return }
        
        view.backgroundColor = .black.withAlphaComponent(0.5)
        view.addSubview(indicatorBg)
        view.addSubview(indicator)
        
        NSLayoutConstraint.activate([
            indicatorBg.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indicatorBg.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicatorBg.widthAnchor.constraint(equalToConstant: 100),
            indicatorBg.heightAnchor.constraint(equalToConstant: 100),
        
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    func start(_ from: UIViewController?, _ completion: (() -> Void)?) {
        from?.present(self, animated: true, completion: completion)
        setupView()
        indicator?.startAnimating()
    }
    
    func stop(_ completion: (() -> Void)?) {
        indicator?.stopAnimating()
        indicator = nil
        dismiss(animated: true, completion: completion)
    }
}


