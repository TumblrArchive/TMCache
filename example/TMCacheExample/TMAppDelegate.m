#import "TMAppDelegate.h"
#import "TMCache.h"
#import "TMExampleView.h"

@implementation TMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
  
    TMExampleView *view = [[TMExampleView alloc] initWithFrame:self.window.rootViewController.view.bounds];
    view.imageURL = [[NSURL alloc] initWithString:@"http://upload.wikimedia.org/wikipedia/commons/6/62/Sts114_033.jpg"];
    view.contentMode = UIViewContentModeScaleAspectFill;
    
    [self.window.rootViewController.view addSubview:view];
    [self.window makeKeyAndVisible];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self tests];
    });
    
    return YES;
}

- (void)tests
{
    NSString *exampleKey = @"TMExampleKey";
    NSString *exampleString = @"Tell me, O Muse, of the man of many devices, who wandered full many ways after he sacked the sacred citadel of Troy.";

    TMCache *cache = [TMCache sharedCache];
    
    [cache clearAllCaches];

    NSData *data = [exampleString dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"example data stored at pointer %p", data);

    [cache setData:data forKey:exampleKey block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"data stored in memory cache");
    }];

    cache.willEvictDataFromMemoryBlock = ^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"%@ -- data at %p is being evicted from memory (key: %@)", cache, data, key);
    };
    
    cache.willEvictDataFromDiskBlock = ^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"%@ -- data is being evicted from disk (key: %@)", cache, key);
    };

    [cache dataForKey:exampleKey block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        if (data) {
            NSLog(@"this data was retrieved from %@: \"%@\"", cache.name, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        } else {
            NSLog(@"no cached data for key: %@", exampleKey);
        }
    }];

    [cache fileURLForKey:exampleKey block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        if (fileURL) {
            NSLog(@"the data is cached on disk at: %@", fileURL);
        } else {
            NSLog(@"no data on disk for key: %@", exampleKey);
        }
    }];

    [cache clearMemoryCache];

    [cache dataForKey:exampleKey block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"second data retrieval (hitting disk this time) \"%@\"", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }];

    [cache removeDataForKey:exampleKey block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"data with key %@ removed from cache", key);
    }];

    [cache dataForKey:exampleKey block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        NSLog(@"the data has been removed from the cache so this should be null: %@", data);
    }];
}

@end
