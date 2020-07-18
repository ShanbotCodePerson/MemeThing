//
//  AppDelegate.swift
//  MemeThing
//
//  Created by Shannon Draeker on 5/22/20.
//  Copyright © 2020 Shannon Draeker. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Use this to suppress warnings about auto layout constraints and make debugging console easier to read
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        // TODO: - delete this since I'm not using badges, or put badges somewhere
//        // Clear the notification badge from the app icon
//        application.applicationIconBadgeNumber = 0
        
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
        // Register for all notifications
        UserController.shared.setUpUser()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Tell the view to display an alert to suggest turning on notifications
        // TODO: - test this
        NotificationCenter.default.post(Notification(name: .notificationsDenied))
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("got here to \(#function) and \(userInfo)")
//        // Handle the notification
//        NotificationHelper.processNotification(withData: userInfo) { (rawValue) in
//            let result = UIBackgroundFetchResult(rawValue: rawValue) ?? UIBackgroundFetchResult.failed
//            completionHandler(result)
//        }
    }
}

// MARK: - Notification Center Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("got here to \(#function) and \(notification)")
        // TODO: - find out which view the user is currently on and don't present an alert if the user is currently in the game
        
//        let userInfo = notification.request.content.userInfo
//        let shouldPresent = NotificationHelper.shouldPresentNotification(withData: userInfo)
        
        // FIXME: - first look at the content of the alert to decide if it's something worth using an alert for or not
        // Present the alert even when the app is open
//        completionHandler(shouldPresent ? [.alert] : [])
        completionHandler([.alert])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("got here to \(#function) and \(response)")
        
        // Handle the notification by directing the user to relevant screen of the app
        NotificationHelper.handleResponse(to: response.notification)
    }
}
