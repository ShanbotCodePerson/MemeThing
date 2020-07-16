//
//  MemeThingError.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/27/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

enum MemeThingError: LocalizedError {
    
    case fsError(Error)
    case couldNotUnwrap
    case noUserFound
    case noSuchUser
    case unknownError // FIXME: - need to convert this to real error, replace all instances of it
    case mergeNeeded
    case alreadyDeleted
    case noData
    case badPhotoFile
    
    var errorDescription: String? {
        switch self {
        case .fsError(let error):
            // FIXME: - better user-friendly error handling needed here
            return "Error fetching data from the cloud: \(error.localizedDescription)"
        case .couldNotUnwrap:
            return "The cloud returned bad data"
        case .noUserFound:
            return "Unable to find user information"
        case .noSuchUser:
            return "There is no user with the given information registered with MemeThing"
        case .unknownError:
            return "Man I have no idea your guess is as good as mine sorry bro"
        case .mergeNeeded:
            return "The Cloud has been updated in the meantime - a merge is needed"
        case .alreadyDeleted:
            return "The game has already been deleted from the cloud"
        case .noData:
            return "The cloud returned bad data"
        case .badPhotoFile:
            return "Unable to save image to cloud"
        }
    }
}
