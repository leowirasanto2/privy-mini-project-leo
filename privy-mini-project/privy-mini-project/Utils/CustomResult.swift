//
//  CustomResult.swift
//  privy-mini-project
//
//  Created by Leo Wirasanto Laia on 28/08/24.
//

import Foundation

enum FaceError: Error {
    case timeout
    case faceUnidentified
}

extension FaceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Request timeout"
        case .faceUnidentified:
            return "Face can't be identified"
        }
    }
}
