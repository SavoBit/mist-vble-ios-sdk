//
//  NotificationHelper.swift
//  Mist-sample-background
//
//  Created by cuongt on 7/15/19.
//  Copyright © 2019 Mist. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationHelper: NSObject {
    
    static func schedule(afterSec elapse: TimeInterval, withTitle title: String, withSub sub: String, withBody body: String, withImageName name: String) {
        
        // create contents
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = sub
        content.body = body
        
        // create image (optional)
        if let imageURL = Bundle.main.url(forResource: name, withExtension: "png") {
            let attachment = try! UNNotificationAttachment(identifier: name, url: imageURL, options: .none)
            content.attachments = [attachment]
        }
        
        // define trigger time
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: elapse, repeats: false)
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
        
        // schedule
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
