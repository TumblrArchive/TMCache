//
//  TMAppDelegate.m
//  TMCacheExample
//
//  Created by Justin Ouellette on 12/21/12.
//  Copyright (c) 2012 Tumblr. All rights reserved.
//

#import "TMAppDelegate.h"
#import "TMPettyCache.h"

@implementation TMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self example];
    });

    return YES;
}

- (void)example
{
    NSString *exampleKey = @"TMExampleKey";
    NSString *exampleString = @"Tell me, O Muse, of the man of many devices, who wandered full many ways after he sacked the sacred citadel of Troy.";

    TMPettyCache *cache = [[TMPettyCache alloc] initWithName:@"TMExampleCache"];

    NSData *data = [exampleString dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"example data: %p", data);

    [cache setData:data forKey:exampleKey];

    cache.willEvictDataBlock = ^(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"notice from %@: data at %p is being evicted from memory (key: %@)", cache, data, key);
    };

    [cache dataForKey:exampleKey block:^(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        if (data) {
            NSLog(@"this string was retrieved from %@: %@", cache.name, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"no cached data for key: %@", exampleKey);
        }
    }];

    [cache fileURLForKey:exampleKey block:^(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        if (fileURL) {
            NSLog(@"the string is cached on disk at: %@", fileURL);
        } else {
            NSLog(@"no data on disk for key: %@", exampleKey);
        }
    }];

    [cache clearMemoryCache];

    [cache dataForKey:exampleKey block:^(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"second string retrieval (hitting disk this time): %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }];

    [cache removeDataForKey:exampleKey];

    [cache dataForKey:exampleKey block:^(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"we have now removed the string from the cache so this should be nil: %@", data);
    }];
}

@end
