//
//  NotificationHelper.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/2/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation

class NotificationHelper {
 
    // MARK: - Define Custom Notification Types

    enum Category: String {
        case newFriendRequest = "NEW_FRIEND_REQUEST"
        case friendRequestResponse = "FRIEND_REQUEST_RESPONSE"
    }
    
    // MARK: - Process Notifications
    
    static func processNotification(with type: Category) {
        switch type {
        case .newFriendRequest:
            print("received new friend request")
                // TODO: - display an alert if app is open?
            // TODO: - refresh tableview if viewing friends list? how to do that?
        case .friendRequestResponse:
            print("received response to friend request")
            // TODO: - display an alert if app is open?
            // TODO: - have an alert waiting next time app is opened?
            // TODO: - refresh tableview if viewing friends list? how to do that?
            UserController.shared.receiveResponseToFriendRequest()
        }
    }
}
