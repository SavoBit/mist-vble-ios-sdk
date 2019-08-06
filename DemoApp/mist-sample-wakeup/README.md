# Steps to see the App Wakup in action

### 1.) Configure the Site Configuration and AP Configuration

#### Site Configuration

   * Go to Organization → Site Configuration → (Choose the site) →
     * Bluetooth based Location Services
          * Enable "vBLE Engagement"
          * Enable "App Wakeup"
     * Location
          * Provide location


#### AP Configuration

Each AP in the Site that you would like to broadcast the app wakeup needs to be configured 
Go to Access Points → (Choose an Access Point for the site) → BLE Settings
Enable "Enable BLE iBeacon"

### 2.) Download sample code 
          https://github.com/mistsys/mist-vble-ios-sdk/tree/mist-sample-wakeup

### 3.) Get the sdk Secret Key from the Mist portal
Go to Organization → Mobile SDK → Copy the key from the "Secret" column (you may need to create an invitation if there is not at least one available)

### 4.) Add the secret key to the sample app
Open the sample app in xCode
In the ViewController.swift file set the values of portalSDKToken to the secret key you got from the portal
     var portalSDKToken: String? = "PPRsreycFghetRHHAPKHDTRH71gVDULVC"


### 5.) Make sure you are in a place not receiving iBeacon information from any Mist AP in the organization. Having access to a single AP (that is configured to the org and for a specific site and map) is very beneficial to trying out this steps. It should be unplugged at this point, so that it does not broadcast any iBeacons.  

### 6.) Run the sample app on an iOS device. Make sure the device has internet connection, Bluetooth On and Location Services On

### 7.) Tap on the blue button "Start Wake Up"
This will use the SDK to get Organization details based on the secret key
Based on these details, it will register beacons to monitor for with Core Location
Wait a few seconds

### 8.) Kill the app from the phone

### 9.) Add a breakpoint in AppDelegate.swift on this line
 MistManager.sharedInstance().connect()
Change the Scheme
On the Xcode menu go to Product → Scheme → Edit Scheme ...
On Run Debug → Info → Launch

### 10.) Change from "Automatically" to "Wait for executable to be launched"

### 11.) Click run in xCode
This will wait for the application to get launched before is starts debugging

### 12.) Connect the AP to the LAN/Ethernet
Once the AP is fully running it will broadcast iBeacons that the iOS device is monitoring for

### 13.) xCode will stop at the breakpoint
This means that iOS has woken up the sample application and informed it through the "launchOptions" parameter that it has been woken up due to a location related event, because the OS received iBeacons the application (in step 7) told it to monitor for.
If this breakpoint is not triggered, try resetting the phones settings, then repeat the steps from step 5.
Click next to continue from the breakpoint
At this point as well, the application has initialized the SDK and is trying to connect

### 14.) Once the SDK has connected it reports the beacons it hears and this gives the Mist portal data to use in calculating the location of the device

### 15.) Go to the Mist portal live view for the map that the AP is configured in
Location → Live View → (Choose the Site) → (Choose the Map)
At this point, a blue person icon should be displayed near the AP (green square) you are using. This confirms that the SDK is connected and the portal is getting the beacon data.

![ImageN](/mist-sample-wakeup/blue-person.png)
