//
//  BaseFullscreenView.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 28/08/24.
//

import UIKit

protocol BaseFullscreenViewProtocol: AnyObject {
    func start(_ from: UIViewController?, _ completion: (() -> Void)?)
    func stop(_ completion: (() -> Void)?)
}

typealias BaseFullscreenView = UIViewController & BaseFullscreenViewProtocol

extension BaseFullscreenViewProtocol {
    func stop(_ completion: (() -> Void)?) {}
}
