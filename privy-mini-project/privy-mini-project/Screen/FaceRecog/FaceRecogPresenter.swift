//
//  FaceRecogPresenter.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 28/08/24.
//

import Foundation

protocol FaceRecogPresenterProtocol: AnyObject {
    func setState(new state: ValidationState)
    func performActionButtonTapped()
    func handleFaceDetectionResult(faceRotationAngle: CGFloat, rotationThreshold: CGFloat)
    var isActionButtonEnabled: Bool { get }
}

class FaceRecogPresenter: FaceRecogPresenterProtocol {
    weak var view: FaceRecogViewProtocol?
    var wireframe: FaceRecogWireframeProtocol?
    var interactor: FaceRecogInteractorProtocol?
    
    var isActionButtonEnabled: Bool {
        return state == .preparation || state == .success
    }
    
    private var state: ValidationState = .preparation {
        didSet {
            view?.onValidationStateChanged(state)
        }
    }
    
    init() {
        
    }
    
    func setState(new state: ValidationState) {
        self.state = state
    }
    
    func performActionButtonTapped() {
        if state == .preparation {
            state = .rotateRight
            return
        }
        
        if state == .success {
//            view?.navigationController?.popViewController(animated: true)
            wireframe?.navigateToNextStep()
            return
        }
    }
    
    func handleFaceDetectionResult(faceRotationAngle: CGFloat, rotationThreshold: CGFloat) {
        switch state {
        case .faceForward:
            if abs(faceRotationAngle) <= rotationThreshold {
                state = .success
            }
        case .rotateLeft:
            if faceRotationAngle < -rotationThreshold {
                state = .faceForward
            }
        case .rotateRight:
            if faceRotationAngle > rotationThreshold {
                state = .rotateLeft
            }
        default:
            break
        }
    }
}
