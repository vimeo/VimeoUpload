//
//  VIMVideoPlayFile.m
//  VimeoNetworking
//
//  Created by Lehrer, Nicole on 5/12/16.
//  Copyright © 2016 Vimeo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "VIMVideoPlayFile.h"
#import "VIMVideoLog.h"

@interface VIMVideoPlayFile()

@property (nonatomic, copy) NSString *expires;

@end

@implementation VIMVideoPlayFile

#pragma mark - NSCoding

+ (void)load
{
    // This appeared to only be necessary for downloaded videos with archived VIMVideoFile's that persisted in a failed state. [NL] 05/15/16
    // E.g. a user has at least one failed download with our legacy VIMVideoFile model, then upgrades to this version.
    // After launch, we must force unwrap the video file in NewDownloadDescriptor as a VIMVideoPlayFile to be in sync with our current model.
    // The following allows us to do so by unarchiving VIMVideoFile as VIMVideoPlayFile.
    [NSKeyedUnarchiver setClass:self forClassName:@"VIMVideoFile"];
}

#pragma mark - VIMMappable

- (void)didFinishMapping
{
    if ([self.expires isKindOfClass:[NSString class]])
    {
        self.expirationDate = [[VIMModelObject dateFormatter] dateFromString:self.expires];
    }
}

- (NSDictionary *)getObjectMapping
{
    return @{@"link_expiration_time": @"expires"};
}

#if TARGET_OS_IOS
- (Class)getClassForObjectKey:(NSString *)key
{
    if ([key isEqualToString:@"log"])
    {
        return [VIMVideoLog class];
    }
    return nil;
}
#endif

#pragma mark - Instance methods

- (BOOL)isExpired
{
    if (!self.expirationDate) // This will yield NSOrderedSame (weird), so adding an explicit check here [AH] 9/14/2015
    {
        return NO;
    }
    
    NSComparisonResult result = [[NSDate date] compare:self.expirationDate];
    
    return (result == NSOrderedDescending);
}

@end
