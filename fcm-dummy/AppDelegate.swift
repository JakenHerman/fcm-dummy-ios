//
//  AppDelegate.swift
//  fcm-dummy
//
//  Created by Jaken Herman on 12/30/24.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    
    // Variables to hold tokens until both are available
    var fcmToken: String?
    var apnsTokenAvailable = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self

        // Request notification authorization
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            } else if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Set APNs token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        apnsTokenAvailable = true
        print("APNs device token retrieved: \(deviceToken)")

        // Attempt subscription if FCM token is already available
        subscribeToPublicTopicIfNeeded()
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Helper method to subscribe to "public" topic only when both tokens are available
    private func subscribeToPublicTopicIfNeeded() {
        if let token = fcmToken, apnsTokenAvailable {
            Messaging.messaging().subscribe(toTopic: "public") { error in
                if let error = error {
                    print("Failed to subscribe to 'public' topic: \(error.localizedDescription)")
                } else {
                    print("Successfully subscribed to 'public' topic")
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print("Foreground notification received: \(userInfo)")
        return [[.alert, .sound]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print("Background notification received: \(userInfo)")
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "None")")
        
        // Store the FCM token and attempt subscription if APNs token is already available
        self.fcmToken = fcmToken
        subscribeToPublicTopicIfNeeded()
    }
}
