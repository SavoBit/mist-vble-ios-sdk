//
//  WakeupUtil.h
//
//  Created by Dinkar Kumar on 9/9/17.
//  Copyright © 2017 Mist. All rights reserved.

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol WakeupUtilDelegate<NSObject>

@optional

- (void)utilityLocationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region;
- (void)utilityLocationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region;
- (void)utilityLocationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion* )region;
- (void)utilityLocationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region;

@end

@interface WakeupUtil : NSObject

@property (nonatomic, weak) id<WakeupUtilDelegate> utilityDelegate;

+(instancetype)sharedInstance;

-(BOOL)isMonitoringAnyBeacons;

// Setup wakeup for exact org uuid
-(void)setupAppWakeupFeatureWithOrgID:(NSString *)orgID;

// Stop monitoring all previously monitored regions
-(void)stopMonitoringRegisteredRegions;

#pragma mark - Specific wakeup features

// Setup wakeup for all org uuid combinations
-(void)setupAppWakeupFeatureWithCyclicalOrgID:(NSString *)orgID;

// Setup wakeup for zeros UUIDs
-(void)setupAppWakeupFeature;

//-(NSArray <NSString *> *) getCyclicalRegionIdentifiers;
//-(NSArray <NSString *> *) getCyclicalRegionIdentifiersWithOrgID;

@end

