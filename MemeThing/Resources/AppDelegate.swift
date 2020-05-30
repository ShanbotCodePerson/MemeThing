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
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
}

