//
//  ViewController.swift
//  mist-sample-wakeup
//
//  Created by cuongt on 7/15/19.
//  Copyright © 2019 Mist Systems. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import MistSDK

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var portakSDKToken: String? = "PEQb2LVkq4P2cbayrR9xYypdBXJYj62D"
    var locationManager: CLLocationManager!
    
    @IBOutlet weak var wakeupBtn: UIButton!
    @IBOutlet weak var statusLbl: UILabel!
    
    override func viewDidLoad() {
        Timer.scheduledTimer(withTimeInterval: TimeInterval(2), repeats: true) { (timer: Timer) in
            self.renderWakeupUI()
        }
        renderWakeupUI()
        requestNotificationPermission()
        requestLocationPermission()
    }
    
    func renderWakeupUI() {
        if WakeupUtil.sharedInstance()!.isMonitoringAnyBeacons() {
            self.statusLbl.text = "The app is monitoring beacons. You can close the app now."
            self.wakeupBtn.setTitle("Stop Wake Up", for: UIControl.State.normal)
        } else {
            self.statusLbl.text = "The app is not monitoring beacons."
            self.wakeupBtn.setTitle("Start Wake Up", for: UIControl.State.normal)
        }
    }
    
    @IBAction func toggleWakeup(_ sender: UIButton) {
        if WakeupUtil.sharedInstance()!.isMonitoringAnyBeacons() {
            WakeupUtil.sharedInstance()!.stopMonitoringRegisteredRegions()
        } else {
            MSTOrgCredentialsManager.enrollDevice(withToken: portakSDKToken, onComplete: { (response, error) in
                if error == nil, response != nil {
                    guard let response = response,
                        let _ = response["name"],
                        let orgID = response["org_id"] as? String,
                        let orgSecret = response["secret"] as? String else {
                            print("ERROR: Cannot enroll device")
                            return
                    }
                    let orgInfo: [AnyHashable: Any] = [
                        kOrgID: orgID,
                        kOrgSecret: orgSecret
                    ]
                    MistManager.sharedInstance().saveOrgInfo(orgInfo)
                    WakeupUtil.sharedInstance().setupAppWakeupFeature(withOrgID: orgID)
                    WakeupUtil.sharedInstance().setupAppWakeupFeature(withCyclicalOrgID: orgID)
                    WakeupUtil.sharedInstance().utilityDelegate = self
                }
            })
        }
        renderWakeupUI()
    }
    
    func requestLocationPermission() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        if (locationManager?.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization)))! {
            locationManager?.requestAlwaysAuthorization()
        }
        if (locationManager?.responds(to: #selector(CLLocationManager.requestWhenInUseAuthorization)))! {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { (granted, error) in
            if granted {
                print("Notification Permission granted")
            } else {
                print("Notification Permission not granted")
            }
        }
    }
}

extension ViewController: WakeupUtilDelegate {
    
    func utilityLocationManager(_ manager: CLLocationManager!, didEnter region: CLRegion!) {
        
        let msg = "didEnter \(region.identifier)"
        NSLog("\(msg)")
        NotificationHelper.schedule(afterSec: 3, withTitle: msg, withSub: msg, withBody: msg, withImageName: "applelogo")
        
        if UIApplication.shared.applicationState == UIApplication.State.background ||
            UIApplication.shared.applicationState == UIApplication.State.inactive {
            
            if !MistManager.sharedInstance().isConnected {
                MistManager.sharedInstance().setWakeUpAppSetting(true)
                MistManager.sharedInstance().backgroundAppSetting(true)
                MistManager.sharedInstance().setSentTimeInBackgroundInMins(0.5, restTimeInBackgroundInMins: 15.0)
                MistManager.sharedInstance().connect()
                
                NotificationHelper.schedule(afterSec: 3, withTitle: "Starting SDK...", withSub: msg, withBody: msg, withImageName: "applelogo")
            }
        }
    }
    
    func utilityLocationManager(_ manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        NSLog("didExitRegion \(region.identifier)")
    }
    
    func utilityLocationManager(_ manager: CLLocationManager!, didDetermineState state: CLRegionState, for region: CLRegion!) {
        NSLog("didDetermineState \(state) \(region.identifier)")
    }
    
    func utilityLocationManager(_ manager: CLLocationManager!, didStartMonitoringFor region: CLRegion!) {
        NSLog("didStartMonitoringFor \(region.identifier)")
    }
    
}
