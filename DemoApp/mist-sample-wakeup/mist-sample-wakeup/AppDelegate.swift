//
//  AppDelegate.swift
//  mist-sample-wakeup
//
//  Created by cuongt on 7/15/19.
//  Copyright © 2019 Mist Systems. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var wakeupInstance = WakeupUtil.sharedInstance()
    var bgTask : UIBackgroundTaskIdentifier?
    
    func startBackgroundTask() {
        self.stopBackgroundTask()
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.stopBackgroundTask()
        })
        DispatchQueue.main.async {
            NotificationHelper.schedule(afterSec: 1, withTitle: "Test", withSub: "Test", withBody: "Test", withImageName: "applelogo")
            if !MistManager.sharedInstance().isConnected {
                MistManager.sharedInstance().setWakeUpAppSetting(true)
                MistManager.sharedInstance().backgroundAppSetting(true)
                MistManager.sharedInstance().setSentTimeInBackgroundInMins(0.5, restTimeInBackgroundInMins: 1)
                MistManager.sharedInstance().connect()
                NotificationHelper.schedule(afterSec: 2, withTitle: "Starting SDK...", withSub: "Test", withBody: "Test", withImageName: "applelogo")
            }
        }
    }
    
    func stopBackgroundTask() {
        if bgTask == nil {
            return
        }
        if bgTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(bgTask!)
            bgTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if let _ = launchOptions?[UIApplication.LaunchOptionsKey.location] {
            self.startBackgroundTask()
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

