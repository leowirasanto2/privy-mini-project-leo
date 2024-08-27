//
//  ViewControllerPreview.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 23/08/24.
//

import Foundation
import SwiftUI

struct ViewControllerPreview: UIViewControllerRepresentable {
    
    var viewControllerBuilder: () -> UIViewController
    
    init(_ viewControllerBuilder: @escaping () -> UIViewController) {
        self.viewControllerBuilder = viewControllerBuilder
      }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        viewControllerBuilder()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // TODO: - let's figure out what can we do here :D
    }
}

