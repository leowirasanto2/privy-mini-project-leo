//
//  FaceRecogInteractor.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 28/08/24.
//

import Foundation

protocol FaceRecogInteractorProtocol: AnyObject {
    func fakeSendFaceVerification()
}

class FaceRecogInteractor: FaceRecogInteractorProtocol {
    weak var presenter: FaceRecogPresenterProtocol?
    
    init() {
        
    }
    
    func fakeSendFaceVerification() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.presenter?.onFaceVerificationReceived(.success(""))
        }
    }
}
