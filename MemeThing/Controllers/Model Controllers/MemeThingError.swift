//
//  MemeThingError.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

enum MemeThingError: LocalizedError {
    
    case ckError(Error)
    case couldNotUnwrap
    case noUserFound
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .ckError(let error):
            return "Error fetching data from the cloud: \(error.localizedDescription)"
        case .couldNotUnwrap:
            return "The cloud returned bad data"
        case .noUserFound:
            return "Unable to find user information"
        case .unknownError:
            return "Man I have no idea your guess is as good as mine sorry bro"
        }
    }
}
