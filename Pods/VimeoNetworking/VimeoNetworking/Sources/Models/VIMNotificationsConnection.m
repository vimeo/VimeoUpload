//
//  VIMNotificationsConnection.m
//  Pods
//
//  Created by Guhit, Fiel on 3/9/17.
//
//

#import "VIMNotificationsConnection.h"
#import "VIMNotification.h"

@interface VIMNotificationsConnection ()

@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *type_count;

@end

@implementation VIMNotificationsConnection

- (NSInteger)supportedNotificationNewTotal
{
    NSArray<NSString *> *supportedNotificationKeys = [[VIMNotification supportedTypeMap] allKeys];
    
    NSInteger total = 0;
    for (NSString *key in supportedNotificationKeys)
    {
        total += self.type_count[key].integerValue;
    }
    
    return total;
}

@end
