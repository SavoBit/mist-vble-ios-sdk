//
//  MistManager.m
//  Mist
//
//  Created by Cuong Ta on 1/20/16.
//  Copyright © 2016 Mist. All rights reserved.
//

#import "MistManager.h"

static NSString *const kOrgCredentialKey = @"com.mist.org_credential";

@interface MistManager () <MSTCentralManagerDelegate, MSTCentralManagerMapDataSource, MSTProximityDelegate>{}

@property (nonatomic, strong) MSTCentralManager *mstCentralManager;
@property (nonatomic, strong) NSDictionary *appSettings;
@property (nonatomic, strong) NSMutableDictionary *callbacks;
@property (nonatomic, strong) NSOperationQueue *backgroundQueue;
@property (nonatomic, strong) NSUUID *mistUUID;
@property (nonatomic, assign) BOOL shouldTestAppModifiedLocation;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) int secondsBehind;
@property (nonatomic) int sdkState;
@property (nonatomic, strong) NSMutableArray *simulateFuncs;
@property (nonatomic) long virtualAPTestMin;
@property (nonatomic, assign) BOOL wakeUpSetting;
@property (nonatomic, assign) BOOL backgroundAppSetting;
@property (nonatomic, assign) double sentTime;
@property (nonatomic, assign) double restTime;

@end

@implementation MistManager

//#define kSettings @"com.mist.org_credential"

static MistManager *_sharedInstance = nil;

+(instancetype)sharedInstance{
    if (_sharedInstance == nil) {
        _sharedInstance = [[self alloc] init];
        _sharedInstance.backgroundQueue = [[NSOperationQueue alloc] init];
    }
    return _sharedInstance;
}

+(void) resetSharedInstance {
    _sharedInstance = nil;
}

-(id)init{
    self = [super init];
    if (self) {
        self.callbacks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)reconnect{
    if (_isConnected) {
        [self disconnect];
        [self connect];
    }
}

-(void)connect{
    self.appSettings = [self getOrgInfo];

    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
        self.secondsBehind = 0;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkIfLEIsDelayed) userInfo:nil repeats:true];
    
    if (_isConnected) {
        NSLog(@"MistManager is still connected. Please call disconnect first");
        return;
    }
    self.zoneEventsMsg = [[NSMutableArray alloc] init];
    self.virtualBeacons = [[NSDictionary alloc] init];
    NSString *env = @"P";
    
    NSLog(@"OrgID: (%@)",[self.appSettings objectForKey:kOrgID]);
    NSLog(@"OrgSecret: (%@)",[self.appSettings objectForKey:kOrgSecret]);
    
    [[MSTRestAPI sharedInstance] logout];
    [[MSTRestAPI sharedInstance] setEnv:env];
    
    if (self.mstCentralManager != nil) {
        [self.mstCentralManager removeNotifier];
        self.mstCentralManager = nil;
    }
    self.mstCentralManager = [[MSTCentralManager alloc] initWithOrgID:[self.appSettings objectForKey:kOrgID]
                                                   AndOrgSecret:[self.appSettings objectForKey:kOrgSecret]];
    self.mstCentralManager.delegate = self;
    self.mstCentralManager.proximityDelegate = self;
    self.mstCentralManager.mapDataSource = self;
    [self.mstCentralManager setShouldCompressData:true];
    [self.mstCentralManager backgroundAppSetting:true];
    [self.mstCentralManager setSentTimeInBackgroundInMins:0.5 restTimeInBackgroundInMins:5];
    [self.mstCentralManager setEnviroment:env];
    [self.mstCentralManager requestAuthorization:AuthorizationTypeUSE];
    [self.mstCentralManager wakeUpAppSetting:self.wakeUpSetting];
    [self.mstCentralManager backgroundAppSetting:self.backgroundAppSetting];
    [self.mstCentralManager setSentTimeInBackgroundInMins:self.sentTime restTimeInBackgroundInMins:self.restTime];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mstCentralManager setAppState:[[UIApplication sharedApplication] applicationState]];
        [self.mstCentralManager startLocationUpdates];
    });
    _isConnected = true;
}

-(void)disconnect{
    [self.mstCentralManager stopLocationUpdates];
    if (_isConnected) {
        if (self.mstCentralManager != nil) {
            [self.mstCentralManager removeNotifier];
            self.mstCentralManager = nil;
        }
        
        self.currentMap = nil;
        self.clientInformation = nil;
    }
    _isConnected = false;
    
    if ([self.timer isValid]) {
        [self.timer invalidate];
        self.timer = nil;
        self.secondsBehind = 0;
    }
}

-(void)addEvent:(NSString *)event forTarget:(id)target{
    @synchronized (self) {
        NSMutableArray *targets = [self.callbacks objectForKey:event];
        if (targets) {
            [targets addObject:target];
        } else {
            NSMutableArray *targets = [[NSMutableArray alloc] init];
            [targets addObject:target];
            [self.callbacks setObject:targets forKey:event];
        }
    }
}

-(void)removeEvent:(NSString *)event forTarget:(id)target{
    @synchronized (self) {
        NSMutableArray *targets = [self.callbacks objectForKey:event];
        int index = -1;
        if (targets) {
            for (int i = 0 ; i < targets.count ; i++) {
                if ([targets objectAtIndex:i] == target) {
                    index = i;
                }
            }
            if (index > -1) {
                [targets removeObjectAtIndex:index];
            }
        }
    }
}

-(void)addEvents:(NSArray *)events forTarget:(id)target{
    [events enumerateObjectsUsingBlock:^(NSString *event, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addEvent:event forTarget:target];
    }];
}

-(void)removeEvents:(NSArray *)events forTarget:(id)target{
    [events enumerateObjectsUsingBlock:^(NSString *event, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeEvent:event forTarget:target];
    }];
}

# pragma mark - Persist Org Info

-(void)saveOrgInfo:(NSDictionary *)orgInfo {
    [[NSUserDefaults standardUserDefaults] setObject:orgInfo forKey:kOrgCredentialKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSDictionary *)getOrgInfo{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kOrgCredentialKey];
}

#pragma mark - MSTCentralManager

#pragma mark - MSTCentralManager features

-(bool)isMSTCentralManagerRunning{
    return self.mstCentralManager.isRunning;
}

-(void)setWakeUpAppSetting:(bool)boolean{
    [self.mstCentralManager wakeUpAppSetting:boolean];
}

#pragma mark - FROM CLOUD

#pragma mark - FIXME: Refactor the following pattern

- (CLLocationCoordinate2D) getLatitudeLongitudeUsingMapOriginForX: (double) x AndY: (double) y{
    return [self.mstCentralManager getLatitudeLongitudeUsingMapOriginForX:x AndY:y];
}

-(void)mistManager:(MSTCentralManager *)manager didConnect:(BOOL)isConnected{
    _isConnected = isConnected;
    NSMutableArray *targets = [self.callbacks objectForKey:@"didConnect"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didConnect:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didConnect:isConnected];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateMap:(MSTMap *)map at:(NSDate *)dateUpdated{
    self.siteId = map.siteId;
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateMap"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateMap:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateMap:map at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateDRMap:(MSTMap *)map at:(NSDate *)dateUpdated{
    self.siteId = map.siteId;
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateDRMap"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateDRMap:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateDRMap:map at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didReceivedAllMaps:(NSDictionary *)maps at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didReceivedAllMaps"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didReceivedAllMaps:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didReceivedAllMaps:maps at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didReceivedVirtualBeacons:(NSArray *)virtualBeacons{
    NSMutableDictionary *oneTimeDict = [[NSMutableDictionary alloc] init];
    [virtualBeacons enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [oneTimeDict setObject:obj forKey:[obj objectForKey:@"id"]];
    }];
    
    self.virtualBeacons = [[NSDictionary alloc] initWithDictionary:oneTimeDict];
    
    NSMutableArray *targets = [self.callbacks objectForKey:@"didReceivedVirtualBeacons"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didReceivedVirtualBeacons:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didReceivedVirtualBeacons:virtualBeacons];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didReceivedClientInformation:(NSDictionary *)clientInformation{
    self.clientInformation = [[NSMutableDictionary alloc] initWithDictionary:clientInformation];
    
    NSMutableArray *targets = [self.callbacks objectForKey:@"didReceivedClientInformation"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didReceivedClientInformation:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didReceivedClientInformation:clientInformation];
                }];
            }
        }
    }
}

-(void)manager:(MSTCentralManager *) manager receivedLogMessage: (NSString *)message forCode:(MSTCentralManagerStatusCode)code{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (code < MSTCentralManagerStatusCodeSentJSON) {
            UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            if (code == MSTCentralManagerStatusCodeDisconnected || code == MSTCentralManagerStatusCodeConnecting) {
    //            [AlertViewCommon showStaticHUDMessage:@"" inView:window forDuration:1];
            } else {
    //            [AlertViewCommon showStaticHUDMessage:@"" inView:window forDuration:3];
            }
        }
        
        if ([self.callbacks objectForKey:@"receivedLogMessage"]) {
            NSMutableArray *targets = [self.callbacks objectForKey:@"receivedLogMessage"];
            if ([targets count] > 0) {
                for (id target in targets) {
                    if ([target respondsToSelector:@selector(manager:receivedLogMessage:forCode:)]) {
                        [self.backgroundQueue addOperationWithBlock:^{
                            [target manager:manager receivedLogMessage:message forCode:code];
                        }];
                    }
                }
            }
        }
        
    });
}

-(void)manager:(MSTCentralManager *)manager receivedVerboseLogMessage:(NSString *)message{
    // write the logs for debugging
    NSLog(@"DEBUG: verboseMsg: %@", message);
    
    if ([self.callbacks objectForKey:@"receivedVerboseLogMessage"]) {
        NSMutableArray *targets = [self.callbacks objectForKey:@"receivedVerboseLogMessage"];
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(manager:receivedVerboseLogMessage:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target manager:manager receivedVerboseLogMessage:message];
                    }];
                }
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didReceiveNotificationMessage:(NSDictionary *)payload{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didReceiveNotificationMessage"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didReceiveNotificationMessage:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didReceiveNotificationMessage:payload];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager willUpdateRelativeLocation:(MSTPoint *)relativeLocation inMaps:(NSArray *)maps at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"willUpdateRelativeLocation"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:willUpdateRelativeLocation:inMaps:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager willUpdateRelativeLocation:relativeLocation inMaps:maps at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager willUpdateLocation:(CLLocationCoordinate2D)location inMaps:(NSArray *)maps withSource:(SourceType)locationSource at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"willUpdateLocation"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:willUpdateLocation:inMaps:withSource:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager willUpdateLocation:location inMaps:maps withSource:locationSource at:dateUpdated];
                }];
            }
        }
    }
}

//DR related changes:
-(void)mistManager:(MSTCentralManager *)manager willUpdateMap:(MSTMap *)map at:(NSDate *)dateUpdated {
    NSMutableArray *targets = [self.callbacks objectForKey:@"willUpdateMap"];
    if (targets) {
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(mistManager:willUpdateMap:at:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target mistManager:manager willUpdateMap:map at:dateUpdated];
                    }];
                }
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateDRRelativeLocation:(NSDictionary *)drInfo inMaps:(NSArray *)maps at:(NSDate *)dateUpdated {
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateDRRelativeLocation"];
    if (targets) {
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(mistManager:didUpdateDRRelativeLocation:inMaps:at:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target mistManager:manager didUpdateDRRelativeLocation:drInfo inMaps:maps at:dateUpdated];
                    }];
                }
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateDRBackendRelativeLocation:(NSDictionary *)drInfo inMaps:(NSArray *)maps at:(NSDate *)dateUpdated {
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateDRBackendRelativeLocation"];
    if (targets) {
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(mistManager:didUpdateDRBackendRelativeLocation:inMaps:at:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target mistManager:manager didUpdateDRBackendRelativeLocation:drInfo inMaps:maps at:dateUpdated];
                    }];
                }
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateDRHeading:(NSDictionary *)drInfo {
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateDRHeading"];
    if (targets) {
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(mistManager:didUpdateDRHeading:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target mistManager:manager didUpdateDRHeading:drInfo];
                    }];
                }
            }
        }
    }
}


-(void)mistManager:(MSTCentralManager *)manager didUpdateRelativeLocation:(MSTPoint *)relativeLocation inMaps:(NSArray *)maps at:(NSDate *)dateUpdated{
    
    [self sendLogs:@{@"didUpdateRelativeLocation":relativeLocation.description}];
    self.secondsBehind = 0;
    
    self.userLocation = relativeLocation;
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateRelativeLocation"];
    
    if (targets) {
        if ([targets count] > 0) {
            for (id target in targets) {
                if ([target respondsToSelector:@selector(mistManager:didUpdateRelativeLocation:inMaps:at:)]) {
                    [self.backgroundQueue addOperationWithBlock:^{
                        [target mistManager:manager didUpdateRelativeLocation:relativeLocation inMaps:maps at:dateUpdated];
                    }];
                }
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateLocation:(CLLocationCoordinate2D)location inMaps:(NSArray *)maps withSource:(SourceType)locationSource at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateLocation"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateLocation:inMaps:withSource:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateLocation:location inMaps:maps withSource:locationSource at:dateUpdated];
                }];
            }
        }
    }
}

- (void) mistManager:(MSTCentralManager *)manager didUpdateSecondEstimate: (MSTPoint *) estimate inMaps: (NSArray *) maps at: (NSDate *) dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateSecondEstimate"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateSecondEstimate:inMaps:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateSecondEstimate:estimate inMaps:maps at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager beaconsSent:(NSMutableArray*)beacons{
    NSMutableArray *targets = [self.callbacks objectForKey:@"beaconsSent"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:beaconsSent:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager beaconsSent:beacons];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager time:(double)time sinceSentForCounter:(NSString *)index{
    NSMutableArray *targets = [self.callbacks objectForKey:@"sinceSentForCounter"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:time:sinceSentForCounter:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager time:time sinceSentForCounter:index];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdatePle:(NSInteger)ple andIntercept:(NSInteger)intercept inMaps:(NSArray *)maps at:(NSDate *)dateUpdated{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdatePle"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdatePle:andIntercept:inMaps:at:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdatePle:ple andIntercept:intercept inMaps:maps at:dateUpdated];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager requestOutTimeInt:(NSTimeInterval)interval{
    NSMutableArray *targets = [self.callbacks objectForKey:@"requestOutTimeInt"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:requestOutTimeInt:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager requestOutTimeInt:interval];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager requestInTimeIntsHistoric:(NSDictionary *)timeIntsHistoric{
    NSMutableArray *targets = [self.callbacks objectForKey:@"requestInTimeIntsHistoric"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:requestInTimeIntsHistoric:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager requestInTimeIntsHistoric:timeIntsHistoric];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateHeading:(CLHeading *)headingInformation{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateHeading"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateHeading:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateHeading:headingInformation];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateLEHeading:(NSDictionary *)heading{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateLEHeading"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateLEHeading:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateLEHeading:heading];
                }];
            }
        }
    }
}


-(void)mistManager:(MSTCentralManager *)manager restartScan:(NSString *)message{
    NSMutableArray *targets = [self.callbacks objectForKey:@"requestInTimeIntsHistoric"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:restartScan:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager restartScan:message];
                }];
            }
        }
    }
}

-(void)mistManager:(MSTCentralManager *)manager didUpdateStatus:(MSTCentralManagerSettingStatus)isEnabled ofSetting:(MSTCentralManagerSettingType)type{
    NSMutableArray *targets = [self.callbacks objectForKey:@"didUpdateStatus"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(mistManager:didUpdateStatus:ofSetting:)]) {
                [self.backgroundQueue addOperationWithBlock:^{
                    [target mistManager:manager didUpdateStatus:isEnabled ofSetting:type];
                }];
            }
        }
    }
}

#pragma mark -

#pragma mark - MSTProximityDelegate

-(void)didDiscoverBeaconProximityInformation:(NSDictionary *)proximityInformation forLocation:(CGPoint)currentLocation{
    NSLog(@"MSTProximityDelegate single = %@",proximityInformation);
}

-(void)didDiscoverBeaconsProximityInformation:(NSArray *)proximityInformations forLocation:(CGPoint)currentLocation{
    NSLog(@"MSTProximityDelegate all = %@",proximityInformations);
}

#pragma mark -

- (void) dispatchSelector:(SEL)selector target:(id)target objects:(NSArray*)objects onMainThread:(BOOL)onMainThread {
    if(target && [target respondsToSelector:selector]) {
        NSMethodSignature* signature = [target methodSignatureForSelector:selector];
        if(signature) {
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
            @try {
                [invocation setTarget:target];
                [invocation setSelector:selector];
                
                if (objects) {
                    NSInteger objectsCount	= [objects count];
                    
                    for(NSInteger i = 0; i < objectsCount; i++) {
                        NSObject *obj = [objects objectAtIndex:i];
                        [invocation setArgument:&obj atIndex:i+2];
                    }
                }
                
                if (onMainThread) {
                    [invocation performSelectorOnMainThread:@selector(invoke)
                                                 withObject:nil
                                              waitUntilDone:NO];
                } else {
                    [invocation performSelector:@selector(invoke)
                                       onThread:[NSThread currentThread]
                                     withObject:nil
                                  waitUntilDone:NO];
                }
            } @catch (NSException * e) {
                [e raise];
            } @finally {
                
            }
        }
    }
}

#pragma mark -

#pragma mark - TO CLOUD

-(void)saveClientInformation:(NSDictionary *)payload{
    [self.mstCentralManager saveClientInformation:[payload mutableCopy]];
}

#pragma mark -

#pragma mark - proxy to childViewController

-(void)handleShowWebContent:(NSUInteger)selectedIndex{
    NSMutableArray *targets = [self.callbacks objectForKey:@"handleShowWebContent"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(handleShowWebContent:)]) {
                [target handleShowWebContent:selectedIndex];
            }
        }
    }
}

-(void)displayNotificationForVBID:(NSString *)vbID{
    NSMutableArray *targets = [self.callbacks objectForKey:@"handleShowWebContent"];
    if ([targets count] > 0) {
        for (id target in targets) {
            if ([target respondsToSelector:@selector(handleShowWebContent:)]) {
                [target displayNotificationForVBID:vbID];
            }
        }
    }
}

#pragma mark - Logging and debugging codes below

+(NSUUID *)getMistUUID{
    return [MistIDGenerator getMistUUID];
}

-(void)sendLogs:(NSDictionary *)data{
    NSLog(@"sendLogs: %@", data);
}

-(void)checkIfLEIsDelayed{
    // increment the seconds that the app doesn't receive back a location
    self.secondsBehind += 1;
    
    // if LE is 2 seconds behind, App will complain
    if (self.secondsBehind > 2) {
        [self sendLogs:@{@"LEISBEHIND":[NSString stringWithFormat:@"Location is behind by %d", self.secondsBehind]}];
    }
}

#pragma mark - MSTCentralManagerMapDataSource

-(MSTCentralManagerMapDataSourceOption)shouldDownloadMap:(nonnull MSTCentralManager *)manager{
    return MSTCentralManagerMapDataSourceOptionDownload;
}

-(nullable UIImage *)mapForMapId:(nonnull NSString *)mapId{
    return nil;
}

-(void)mistCentralManager:(nonnull MSTCentralManager *)mistManager downloadMapWithInfo:(nonnull NSString *)info{
    NSLog(@"downloadMapWithInfo = %@", info);
}

#pragma mark - Mocking functions

-(id)getTargetsForKey:(NSString *)key{
    return [self.callbacks objectForKey:key];
}

// MARK: Wake up Features

-(void) wakeUpAppSetting:(bool) boolean {
    self.wakeUpSetting = boolean;
    [self.mstCentralManager wakeUpAppSetting:boolean];
}

-(void) backgroundAppSetting:(bool) boolean {
    self.backgroundAppSetting = boolean;
    [self.mstCentralManager backgroundAppSetting:boolean];
}

-(void) setSentTimeInBackgroundInMins:(double)sentTime restTimeInBackgroundInMins:(double) restTime {
    self.sentTime = sentTime;
    self.restTime = restTime;
    [self.mstCentralManager setSentTimeInBackgroundInMins:sentTime restTimeInBackgroundInMins:restTime];
}

-(void) setSentWithoutRest {
    [self.mstCentralManager sendWithoutRest];
}

@end
