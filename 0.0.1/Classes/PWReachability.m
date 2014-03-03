//
//  PWReachability.m
//  Framework
//
//  Created by platzerworld on 03.03.14.
//  Copyright (c) 2014 platzerworld. All rights reserved.
//
#import <SystemConfiguration/CaptiveNetwork.h>
#import "PWReachability.h"

@implementation PWReachability

NSString *intranetSSID = @"platzerworld";
NetworkStatus lastNetworkStatus;
NetworkStatus currentNetworkStatus;
NSString* lastWifiSSID;
KEZNetworkStatus networkDirection;


- (NSString *)getCurrentWifiSSID {
    
    NSString *ssid = nil;
    NSArray *ifs = (__bridge  id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge  id)CNCopyCurrentNetworkInfo((__bridge  CFStringRef)ifnam);
        if (info[@"SSID"]) {
            ssid = [info valueForKey:@"SSID"];
        }
    }
    return ssid;
}


- (void)startNetworkObserver{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus) name:kReachabilityChangedNotification object:nil];
    internetReachable = [Reachability reachabilityForInternetConnection];
    [internetReachable startNotifier];
    [self checkNetworkStatus];
}

- (void) stopNetworkObserver{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void) testWiFi{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self canExecuteRequestWithCheckWiFiChanged];
}

-(void) checkNetworkStatus
{
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    {
        case NotReachable:
        {
            self.internetActive = NO;
            self.isNotConnectedToIntranet = NO;
            break;
        }
        case ReachableViaWiFi:
        {
            NSString *currentSSID =  [self getCurrentWifiSSID];
            if ([currentSSID isEqualToString:intranetSSID]) {
                self.isNotConnectedToIntranet = NO;
            } else {
                self.isNotConnectedToIntranet = YES;
            }
            self.internetActive = YES;
            break;
        }
        case ReachableViaWWAN:
        {
            self.internetActive = YES;
            self.isNotConnectedToIntranet = YES;
            break;
        }
    }
    
    [self checkWLANWithSSID:[self getCurrentWifiSSID]];
    
}

-(void) checkWLANWithSSID: (NSString*) currentWifiSSID

{
    NSString* message;
    BOOL canExecute = NO;
    networkDirection = Unknown;
    
    currentNetworkStatus = [internetReachable currentReachabilityStatus];
    
    if(currentNetworkStatus == lastNetworkStatus)
    {
        if(currentNetworkStatus == ReachableViaWiFi)
        {
            if([lastWifiSSID isEqualToString:currentWifiSSID])
            {
                message = [NSString stringWithFormat: @"WiFi not changed audi: %@, lastid: %@, currentid: %@",intranetSSID,  lastWifiSSID, currentWifiSSID];
                networkDirection = NotChanged;
            }else
            {
                if([intranetSSID isEqualToString:currentWifiSSID])
                {
                    message = [NSString stringWithFormat: @"From WLAN to Intranet: %@, lastid: %@, currentid: %@",intranetSSID,  lastWifiSSID, currentWifiSSID];
                    networkDirection = FromWLANToIntranet;
                    canExecute = YES;
                }
                else if([intranetSSID isEqualToString:lastWifiSSID])
                {
                    message = [NSString stringWithFormat: @"From Intranet to WLAN: %@, lastid: %@, currentid: %@",intranetSSID,  lastWifiSSID, currentWifiSSID];
                    networkDirection = FromIntranetToWLAN;
                    canExecute = NO;
                }
                else
                {
                    message = [NSString stringWithFormat: @"Unknown: %@, lastid: %@, currentid: %@",intranetSSID,  lastWifiSSID, currentWifiSSID];
                    networkDirection = Unknown;
                }
            }
            
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"WIFI" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }
    else
    {
        if(lastNetworkStatus == ReachableViaWiFi && currentNetworkStatus == ReachableViaWWAN)
        {
            if([lastWifiSSID isEqualToString:intranetSSID])
            {
                networkDirection = FromIntranetTo3G;
                self.isRestartRequired = NO;
                message = [NSString stringWithFormat:@"From INTRANET to 3G, SSID: %@", lastWifiSSID];
            }else
            {
                networkDirection = FromWLANTo3G;
                self.isRestartRequired = YES;
                message = [NSString stringWithFormat:@"From WLAN to 3G, SSID: %@", lastWifiSSID];
            }
        }
        else if(lastNetworkStatus == ReachableViaWWAN && currentNetworkStatus == ReachableViaWiFi)
        {
            if([currentWifiSSID isEqualToString:intranetSSID])
            {
                networkDirection = From3GToIntranet;
                self.isRestartRequired = NO;
                message = [NSString stringWithFormat:@"From 3G to INTRANET, SSID: %@", currentWifiSSID];
            }else
            {
                networkDirection = From3GToWLAN;
                self.isRestartRequired = YES;
                message = [NSString stringWithFormat:@"3G to WLAN, SSID: %@", currentWifiSSID];
            }
        }
        else if(lastNetworkStatus == NotReachable && currentNetworkStatus == ReachableViaWiFi)
        {
            if([currentWifiSSID isEqualToString:intranetSSID])
            {
                networkDirection = FromUnknownToIntranet;
                self.isRestartRequired = YES;
                message = [NSString stringWithFormat:@"From NotReachable to WLAN."];
            }else
            {
                networkDirection = FromUnknownToWLAN;
                self.isRestartRequired = YES;
                message = [NSString stringWithFormat:@"From NotReachable to WLAN."];
            }
            
        }
        else if(lastNetworkStatus == NotReachable && currentNetworkStatus == ReachableViaWWAN)
        {
            networkDirection = FromUnknownTo3G;
            self.isRestartRequired = YES;
            message = [NSString stringWithFormat:@"From NotReachable to 3G"];
        }
        else if(lastNetworkStatus == ReachableViaWiFi &&[intranetSSID isEqualToString:lastWifiSSID] && currentNetworkStatus == NotReachable)
        {
            networkDirection = FromWLANToUnknown;
            self.isRestartRequired = YES;
            message = [NSString stringWithFormat:@"From Intranet to NotReachable"];
            
        }
        else if(lastNetworkStatus == ReachableViaWiFi && ![intranetSSID isEqualToString:lastWifiSSID] && currentNetworkStatus == NotReachable)
        {
            networkDirection = FromIntranetoUnknown;
            self.isRestartRequired = YES;
            message = [NSString stringWithFormat:@"From WLAN to NotReachable"];
        }
        
        
        else
        {
            NSLog(@"Changed NetworkStatus from other NetworkStatus");
            networkDirection = Unknown;
            self.isRestartRequired = NO;
            message = @"OTHER NETWORK STATE";
        }
        NSLog(@"%@", message);
        
        
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"TEST" message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil];
        [alertView show];
    }
    lastWifiSSID = currentWifiSSID;
    lastNetworkStatus = [internetReachable currentReachabilityStatus];
}


- (BOOL) canExecuteRequestWithCheckWiFiChanged
{
    [self checkWLANWithSSID:[self getCurrentWifiSSID]];
    BOOL canExecute = NO;
    return canExecute;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
