//
//  WakeupUtil.h
//
//  Created by Dinkar Kumar on 9/9/17.
//  Copyright © 2017 Mist. All rights reserved.

#import "WakeupUtil.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

static NSString *const OrgRegionID = @"OrgRegion";
static NSString *const BeaconRegionID = @"BeaconRegion";

@interface WakeupUtil () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) UIBackgroundTaskIdentifier bgTaskID;

@end

@implementation WakeupUtil

+(instancetype)sharedInstance {
    static WakeupUtil *utility = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        utility = [[self alloc] init];
    });
    return utility;
}

-(void)getLocationManager {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.locationManager == nil) {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            self.locationManager.pausesLocationUpdatesAutomatically = NO;
            self.locationManager.allowsBackgroundLocationUpdates = YES;
        }
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self.locationManager requestAlwaysAuthorization];
        }
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
    });
}

-(BOOL)isMonitoringAnyBeacons{
    return self.locationManager.monitoredRegions.count > 0;
}

-(void)setupAppWakeupFeatureWithCyclicalOrgID:(NSString *)orgID{
    if (orgID.length > 2) {
        NSString *shortOrgID = [orgID substringToIndex: orgID.length - 2];
        shortOrgID = [NSString stringWithFormat:@"%@%@", shortOrgID, @"0"];
        [self setupCyclicalBeaconRegions:shortOrgID withRegionNamePrefix:OrgRegionID];
    }
}

-(void)setupAppWakeupFeature {
    NSString *uuid = @"00000000-0000-0000-0000-00000000";
    [self setupCyclicalBeaconRegions:uuid withRegionNamePrefix:BeaconRegionID];
}
    
//Setup app wake up feature with org ID as identifier:
-(void)setupAppWakeupFeatureWithOrgID:(NSString *)orgID{
    [self getLocationManager];
    
    //Start monitoring for region
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:orgID] identifier:orgID];
    beaconRegion.notifyOnEntry = YES;
    beaconRegion.notifyOnExit = YES;
    beaconRegion.notifyEntryStateOnDisplay = YES;
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
}

-(void)setupCyclicalBeaconRegions:(NSString *)uuid withRegionNamePrefix:(NSString *)beaconRegionID {
    [self getLocationManager];
    
    NSArray *hex = @[@"a", @"b", @"c", @"d", @"e", @"f"];
    NSMutableArray *uuidArray = [[NSMutableArray alloc] initWithArray:@[]];
    if ([beaconRegionID compare:BeaconRegionID] == NSOrderedSame) {
        for (int i = 0; i < 16; i++) {
            if (i < 10) {
                [uuidArray addObject:[NSString stringWithFormat:@"%@000%d",uuid,i]];
            } else if (i < 16){
                [uuidArray addObject:[NSString stringWithFormat:@"%@000%@",uuid,hex[i-10]]];
            } else {
                [uuidArray addObject:[NSString stringWithFormat:@"%@00%d",uuid,i-6]];
            }
        }
    } else if ([beaconRegionID compare:OrgRegionID] == NSOrderedSame) {
        for (int i = 0; i < 16; i++) {
            if (i < 10) {
                [uuidArray addObject:[NSString stringWithFormat:@"%@%d",uuid,i]];
            } else if (i < 16){
                [uuidArray addObject:[NSString stringWithFormat:@"%@%@",uuid,hex[i-10]]];
            } else {
                [uuidArray addObject:[NSString stringWithFormat:@"%@%d",uuid,i-6]];
            }
        }
    }
    
    CLBeaconRegion *beaconRegion;
    int counter = 0;
    for (NSString *uuid in uuidArray) {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:uuid] identifier:[beaconRegionID stringByAppendingString:[NSString stringWithFormat:@"%d", counter]]];
        beaconRegion.notifyOnEntry = YES;
        beaconRegion.notifyOnExit = YES;
        beaconRegion.notifyEntryStateOnDisplay = YES;
        NSLog(@"Start monitoring beacons %@ %@ %@ %@", beaconRegion.identifier, beaconRegion.proximityUUID, beaconRegion.major, beaconRegion.minor);
        [self.locationManager startMonitoringForRegion:beaconRegion];
        [self.locationManager startRangingBeaconsInRegion:beaconRegion];
        counter++;
    }
}

//Stop app from monitoring for regions:
-(void)stopMonitoringRegisteredRegions {
    if (self.locationManager != nil) {
        for (CLBeaconRegion *beaconRegion in self.locationManager.monitoredRegions) {
            NSLog(@"Stop monitoring beacons %@ %@ %@ %@", beaconRegion.identifier, beaconRegion.proximityUUID, beaconRegion.major, beaconRegion.minor);
            [self.locationManager stopMonitoringForRegion:beaconRegion];
            [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
        }
    }
}

#pragma mark Utility Function

- (BOOL)isValidObject:(id)object {
    BOOL validObject = YES;
    if ( (object == nil) || ([object isKindOfClass:[NSNull class]])) {
        validObject = NO;
    }
    return validObject;
}

#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"didEnterRegion %@", region);
    if([self.utilityDelegate respondsToSelector:@selector(utilityLocationManager:didEnterRegion:)]) {
        [self.utilityDelegate utilityLocationManager:manager didEnterRegion:region];
    }
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"didExitRegion %@", region);
    if([self.utilityDelegate respondsToSelector:@selector(utilityLocationManager:didExitRegion:)]) {
        [self.utilityDelegate utilityLocationManager:manager didExitRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion* )region {
    NSLog(@"didDetermineState %ld %@", (long)state, region);
    if ([region isKindOfClass:[CLBeaconRegion class]] && state == CLRegionStateInside) {
        [self locationManager:manager didEnterRegion:region];
        NSLog(@"State: INSIDE %@", [region identifier]);
    } else if ([region isKindOfClass:[CLBeaconRegion class]] && (state == CLRegionStateOutside || state == CLRegionStateUnknown)) {
        if(state == CLRegionStateUnknown) {
            NSLog(@"State: UNKNOWN %@", [region identifier]);
        } else {
            NSLog(@"State: OUTSIDE %@", [region identifier]);
        }
        [self locationManager:manager didExitRegion:region];
    }
    if([self.utilityDelegate respondsToSelector:@selector(utilityLocationManager:didDetermineState:forRegion:)]) {
        [self.utilityDelegate utilityLocationManager:manager didDetermineState:state forRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *) manager didStartMonitoringForRegion:(CLRegion *) region {
    if([self.utilityDelegate respondsToSelector:@selector(utilityLocationManager:didStartMonitoringForRegion:)]) {
        [self.utilityDelegate utilityLocationManager:manager didStartMonitoringForRegion:region];
    }
}

#pragma mark -

//Return the list of uuid identifiers for the cyclical beacons:
//-(NSArray <NSString *> *) getCyclicalRegionIdentifiers {
//    NSMutableArray *uuidIdentifiers = [[NSMutableArray alloc] initWithCapacity:16];
//    for (int i = 0 ; i < 16; i++) {
//        NSString *beaconRegionIdentifier = [NSString stringWithFormat:@"%@%d", BeaconRegionID, i];
//        [uuidIdentifiers addObject:beaconRegionIdentifier];
//    }
//    return uuidIdentifiers;
//}
//
////return the list of uuids for cyclical beacons with Org ID:
//-(NSArray <NSString *> *) getCyclicalRegionIdentifiersWithOrgID {
//    NSMutableArray *uuidIdentifiers = [[NSMutableArray alloc] initWithCapacity:16];
//    for (int i = 0 ; i < 16; i++) {
//        NSString * beaconRegionIdentifier = [NSString stringWithFormat:@"%@%d", OrgRegionID, i];
//        [uuidIdentifiers addObject:beaconRegionIdentifier];
//    }
//    return uuidIdentifiers;
//}

@end
