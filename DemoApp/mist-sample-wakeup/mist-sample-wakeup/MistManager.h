//
//  MistManager.h
//  Mist
//
//  Created by Cuong Ta on 1/20/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MistSDK/MistSDK.h>

/* MistManager - a proxy object for the SDK to interface with other viewControllers */

static NSString *const kClientID = @"client_uuid";
static NSString *const kOrgID = @"org_id";
static NSString *const kOrgSecret = @"org_secret";

@interface MistManager : NSObject

@property (nonatomic, strong) NSDictionary *virtualBeacons;
@property (nonatomic, strong) NSMutableArray *zoneEventsMsg;
@property (nonatomic, strong) MSTDeviceClient *client;
@property (nonatomic, strong) NSMutableDictionary *clientInformation;
@property (nonatomic, strong) MSTMap *currentMap;
@property (nonatomic, strong) NSDictionary *lockscreenInfo;
@property (nonatomic, assign) NSString *sessionid;
@property (nonatomic, assign) NSString *csrftoken;
@property (nonatomic, strong) NSString *siteId;
@property (nonatomic, strong) MSTPoint *userLocation;
@property (nonatomic) bool enableUDP;
@property (nonatomic) bool shouldReconnect;
@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) BOOL didAlreadyStart;

+(instancetype)sharedInstance;

+(void) resetSharedInstance;

/**
 *  Connect to the Mist Cloud
 */
-(void)connect;

/**
 *  Disconnect from the Mist Cloud
 */
-(void)disconnect;

/**
 *  Disconect and reconnect only if Mist Cloud is currently connected
 */
-(void)reconnect;

/**
 *  Subscribe to event and pass a target to handle the event
 *
 *  @param event The event to register.
 *  @param target The handler for the event.
 */
-(void)addEvent:(NSString *)event forTarget:(id)target;

/**
 *  Unsubscribe to event and pass a target to handle the event
 *
 *  @param event The event to unregister.
 *  @param target The handler for the event.
 */
-(void)removeEvent:(NSString *)event forTarget:(id)target;

/**
 *  Subscribe to event and pass a target to handle the event
 *
 *  @param event The event to register.
 *  @param target The handler for the event.
 */
-(void)addEvents:(NSArray *)events forTarget:(id)target;

/**
 *  Unsubscribe to event and pass a target to handle the event
 *
 *  @param events The event to unregister.
 *  @param targets The handler for the event.
 */
-(void)removeEvents:(NSArray *)events forTarget:(id)target;

/**
 *  Update the client information
 *
 *  @param payload The payload to save to the client information
 */
-(void)saveClientInformation:(NSDictionary *)payload;

/**
 *  Handle the registration of lock screen notification. Set the enableLockScreenNotification variable and then call this function.
 */
-(void)handleRegisterLockScreenNotification;

#pragma mark - MSTCentralManager features

/**
 * Check if the SDK is still connect, scanning beacons etc. 
 * Use to before attempting to disconnect. It may not be connected.
 */
-(bool) isMSTCentralManagerRunning;

/**
 * Setting the wakeup feature, so SDK can attempt to scan in the background.
 */
-(void) setWakeUpAppSetting:(bool)boolean;

#pragma mark - proxy to childViewController

-(void)handleShowWebContent:(NSUInteger)index;

-(void)displayNotificationForVBID:(NSString *)vbID;

#pragma mark -

- (CLLocationCoordinate2D) getLatitudeLongitudeUsingMapOriginForX: (double) x AndY: (double) y;

/**
 *  Retrieve the current Mist UUID that was used to identify the client.
 *
 *  @return uuid NSUUID
 */
+(NSUUID *)getMistUUID;

/**
 * Save org information
 */
-(void)saveOrgInfo:(NSDictionary *)orgInfo;

/**
 * Get org information
 */
-(NSDictionary *)getOrgInfo;

/*background control methods*/

/**
 Set wakeup app setting.

 @param boolean True or false
 */
-(void) wakeUpAppSetting:(bool) boolean;

/**
 Set flag for the background app setting.

 @param boolean True or false.
 */
-(void) backgroundAppSetting:(bool) boolean;

/**
 Set the MistSDK backend send and rest time, when the app is sent to the background.

 @param sentTime Time for which app sends data to backend in the background.
 @param restTime Time for which the app does not communicate with the backend when in the background.
 */
-(void) setSentTimeInBackgroundInMins:(double)sentTime restTimeInBackgroundInMins:(double) restTime;

/**
 Send data to the backend in the background.
 */
-(void) setSentWithoutRest;

@end
