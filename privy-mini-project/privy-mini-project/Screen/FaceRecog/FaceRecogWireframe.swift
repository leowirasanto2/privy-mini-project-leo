//
//  FaceRecogWireframe.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 28/08/24.
//

import UIKit

protocol FaceRecogWireframeProtocol: AnyObject {
    func navigateToNextStep()
}

class FaceRecogWireframe: FaceRecogWireframeProtocol {
    let navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func navigateToNextStep() {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .red
        
        // replacing last viewcontroller
        navigationController?.viewControllers.removeLast()
        navigationController?.viewControllers.append(viewController)
    }
    
    static func createView(_ navigationController: UINavigationController? = nil) -> FaceRecogView {
        let wireframe = FaceRecogWireframe(navigationController: navigationController)
        let interactor = FaceRecogInteractor()
        let presenter = FaceRecogPresenter()
        presenter.wireframe = wireframe
        presenter.interactor = interactor
        interactor.presenter = presenter
        let view = FaceRecogView()
        presenter.view = view
        view.presenter = presenter
        return view
    }
}
