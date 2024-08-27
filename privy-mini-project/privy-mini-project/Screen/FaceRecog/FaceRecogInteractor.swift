//
//  FaceRecogInteractor.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 28/08/24.
//

import Foundation

protocol FaceRecogInteractorProtocol: AnyObject {
    
}

class FaceRecogInteractor: FaceRecogInteractorProtocol {
    weak var presenter: FaceRecogPresenterProtocol?
    
    init() {
        
    }
}
