//
//  AppDelegate.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Clear the notification badge from the app icon
        application.applicationIconBadgeNumber = 0
        
        // Request permission to send notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
            // Handle any errors
            if let error = error {
                // TODO: - better error handling, present alert
                print("Error in \(#function) : \(error.localizedDescription) \n---\n \(error)")
            }
            
            // Handle successfully registering
            if success {
                DispatchQueue.main.async { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
        
        return true
    }
    
    // MARK: - Registering for Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // TODO: - in user controller and meme controller, register for notifications
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // TODO: - display an alert to suggest turning on notifications
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // TODO: - handle receiving a remote notification
        // FIXME: - only works if the app is open - need to handle background notifications too
        print("got here!")
        // FIXME: - way to find notifications that came in while the app was closed?
        // Parse the notification data to find out what type of notification it is
        guard let aps = userInfo["aps"] as? NSDictionary,
            let category = aps["category"] as? String,
            let notificationType = NotificationStrings(rawValue: category)
            else { return }
        
        switch notificationType {
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

