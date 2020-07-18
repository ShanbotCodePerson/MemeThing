//
//  NotificationHelper.swift
//  MemeThing
//
//  Created by Shannon Draeker on 6/2/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationHelper {
    
    // MARK: - Create Custom Notifications

    static func createFriendRequestNotification(_ friendRequest: FriendRequest) {
        // Create the notification
        let notificationContent = UNMutableNotificationContent()
        
        // Add the identifier so that the notification can be received correctly
        notificationContent.categoryIdentifier = Category.newFriendRequest.rawValue
        
        // Set up the title, body, and sound of the notification
        notificationContent.title = "New Friend Request"
        notificationContent.body = "You have received a friend request from \(friendRequest.fromName) on MemeThing"
//        notification.sound = .default
        // FIXME: - uncomment the sound
        
        // Set up the destination of the notification
        
        // TODO: - Allow the user to respond to the friend request by long-pressing on the notification
        
        // Display the notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: trigger))
    }
    
    // MARK: - Define Custom Notification Types
    
    enum Category: String {
        case newFriendRequest = "NEW_FRIEND_REQUEST"
        case friendRequestResponse = "FRIEND_REQUEST_RESPONSE"
        case newGameInvitation = "NEW_GAME_INVITATION"
        case gameUpdate = "GAME_UPDATE"
    }
    
    // MARK: - Process Notifications
    
    // Navigate to the relevant screen of the app when the user taps on a notification
    static func handleResponse(to notification: UNNotification) {
        guard let category = Category(rawValue: notification.request.content.categoryIdentifier) else { return }
        
        switch category {
        case .newFriendRequest:
            NotificationCenter.default.post(Notification(name: .toFriendsView))
        case .friendRequestResponse:
            NotificationCenter.default.post(Notification(name: .toFriendsView))
        case .newGameInvitation:
            NotificationCenter.default.post(Notification(name: .toGamesView))
        case .gameUpdate:
            // FIXME: - this needs some complicated logic
            print("game update - fill this out later")
        }
    }
    
//    // Decide if the notification should be presented to the user
//    static func shouldPresentNotification(withData data: [AnyHashable : Any]) -> Bool {
//        guard let ckNotification = CKQueryNotification(fromRemoteNotificationDictionary: data),
//            let category = ckNotification.category,
//            let notificationType = NotificationHelper.Category(rawValue: category)
////            let recordIDChanged = ckNotification.recordID
//            else { return false }
//        
//        // Present all the notifications except for certain updates to the game
//        if notificationType != .gameUpdate { return true }
//        
//        // TODO: - need to fetch the game and look at it to determine what sort of change happened, or else include desired keys in notification?
//        return false
//    }
}

// MARK: - Local Notification Names

extension Notification.Name {
    static let friendsUpdate = Notification.Name("friendsUpdate")
    static let toFriendsView = Notification.Name("toFriendsView")
    static let toGamesView = Notification.Name("toGamesView")
    static let closeLeaderboard = Notification.Name("closeLeaderboard")
    static let updateListOfGames = Notification.Name("updateListOfGames")
    static let updateWaitingView = Notification.Name("updateWaitingView")
    static let toCaptionsView = Notification.Name("toCaptionsView")
    static let toResultsView = Notification.Name("toResultsView")
    static let toNewRound = Notification.Name("toNewRound")
    static let toGameOver = Notification.Name("toGameOver")
    static let toMainMenu = Notification.Name("toMainMenu")
    static let notificationsDenied = Notification.Name("notificationsDenied")
}

