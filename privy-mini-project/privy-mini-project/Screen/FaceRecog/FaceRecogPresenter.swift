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
    func onFaceVerificationReceived(_ result: Result<String, FaceError>)
    
    var isActionButtonEnabled: Bool { get }
    var isDetectFaceEnabled: Bool { get set }
}

class FaceRecogPresenter: FaceRecogPresenterProtocol {
    weak var view: FaceRecogViewProtocol?
    var wireframe: FaceRecogWireframeProtocol?
    var interactor: FaceRecogInteractorProtocol?
    var isDetectFaceEnabled: Bool = false
    
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
    
    func onFaceVerificationReceived(_ result: Result<String, FaceError>) {
        view?.hideLoading { [weak self] in
            switch result {
            case .success:
                self?.view?.showSuccessScreen {
                    self?.setState(new: .success)
                    self?.wireframe?.navigateToNextStep()
                }
            case .failure(let failure):
                self?.setState(new: .failed)
                print(failure.localizedDescription)
            }
        }
    }
    
    func setState(new state: ValidationState) {
        self.state = state
    }
    
    func performActionButtonTapped() {
        if state == .preparation {
            isDetectFaceEnabled = true
            state = .rotateRight
            return
        }
        
        if state == .success {
            wireframe?.navigateToNextStep()
            return
        }
    }
    
    func handleFaceDetectionResult(faceRotationAngle: CGFloat, rotationThreshold: CGFloat) {
        switch state {
        case .faceForward:
            if abs(faceRotationAngle) <= rotationThreshold {
                self.view?.showLoading { [weak self] in
                    self?.interactor?.fakeSendFaceVerification()
                }
                self.isDetectFaceEnabled = false
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
