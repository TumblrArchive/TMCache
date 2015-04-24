//
//  TMCacheBackgroundTaskManager.h
//  TMCache
//
//  Created by Bryan Irace on 4/24/15.
//  Copyright (c) 2015 Tumblr. All rights reserved.
//

@import UIKit;

@protocol TMCacheBackgroundTaskManager <NSObject>

- (UIBackgroundTaskIdentifier)beginBackgroundTask;

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;

@end
