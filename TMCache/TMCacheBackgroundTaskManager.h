//
//  TMCacheBackgroundTaskManager.h
//  TMCache
//
//  Created by Bryan Irace on 4/24/15.
//  Copyright (c) 2015 Tumblr. All rights reserved.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
#import <UIKit/UIKit.h>
#else
typedef NSUInteger UIBackgroundTaskIdentifier;
#endif

/**
 A protocol that classes who can begin and end background tasks can conform to. This protocol provides an abstraction in
 order to avoid referencing `+ [UIApplication sharedApplication]` from within an iOS application extension.
 */
@protocol TMCacheBackgroundTaskManager <NSObject>

/**
 Marks the beginning of a new long-running background task.
 
 @return A unique identifier for the new background task. You must pass this value to the `endBackgroundTask:` method to
 mark the end of this task. This method returns `UIBackgroundTaskInvalid` if running in the background is not possible.
 */
- (UIBackgroundTaskIdentifier)beginBackgroundTask;

/**
 Marks the end of a specific long-running background task.
 
 @param identifier An identifier returned by the `beginBackgroundTaskWithExpirationHandler:` method.
 */
- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;

@end
