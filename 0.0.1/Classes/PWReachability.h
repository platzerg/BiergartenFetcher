//
//  PWReachability.h
//  Framework
//
//  Created by platzerworld on 03.03.14.
//  Copyright (c) 2014 platzerworld. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Reachability.h>



typedef NS_ENUM(NSInteger, KEZNetworkStatus) {
    Unknown = -1,
    NotChanged = 0,
    
    From3GToWLAN = 1,
    From3GToIntranet = 2,
    From3GToUnknown = 3,
    
    FromWLANTo3G = 4,
    FromWLANToIntranet = 5,
    FromWLANToUnknown = 6,
    
    FromIntranetTo3G = 7,
    FromIntranetToWLAN = 8,
    FromIntranetoUnknown = 9,
    
    FromUnknownTo3G = 10,
    FromUnknownToWLAN = 11,
    FromUnknownToIntranet = 12
    
};

@class Reachability;
@interface PWReachability : NSObject
{
    Reachability *internetReachable;
}


@property (nonatomic) BOOL internetActive;
@property (nonatomic) BOOL isNotConnectedToIntranet;
@property (nonatomic) BOOL isRestartRequired;

- (void)startNetworkObserver;
- (void) stopNetworkObserver;

-(void) checkWLANWithSSID: (NSString*) currentWifiSSID;
- (void) checkNetworkStatus;
- (NSString*) getCurrentWifiSSID;

- (void) testWiFi;

@end
