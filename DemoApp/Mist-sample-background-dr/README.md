## Mist Sample Background DR
This application demonstrates how to handle the background state using Mist SDK - Dead Reakoning(DR).

### Prerequisites
For running this application you need Mobile SDK secret, which can be obtained from the Mist Portal (Organization —> Mobile SDK  —> secret)

### Manual Installation:
Drag and drop the MistSDK.framework file in your xcode project. 

### Classes:
MainViewController.Swift:
This class will input Mobile SDK secret in TextField.

ViewController.Swift:
This class imports the Mist SDK. It implements the MSTCentralManagerDelegate methods given below. 
didConnect
didUpdateDRMap
didUpdateDRRelativeLocation

### Background Settings:
Mist SDK do have power optimised way of working in background for the use case of analytics. You can use sendWithRest() callback to send the location data every second in background.

You also need to enable 'When-in-use' or 'Always' location services from the device setting.

### Support
For more information, refer Mist SDK documentation [wiki page](https://github.com/mistsys/mist-vble-ios-sdk/wiki) or contact <support@mist.com>
