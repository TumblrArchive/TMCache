### 2.1 -- 2015 May 8 ###

Removes the need for the explicit memory warning and application background handling, which was an ill-advised change in 2.0.

The other part of the 2.0 release still applies; you need to explicitly provide an object that knows how to vend background tasks in order for operations to continue after your application has been backgrounded.

### 2.0.0 -- 2015 April 27 ###

2.0.0 removes all references to `UIApplication sharedApplication`. As of iOS 8, this method is annotated with `NS_EXTENSION_UNAVAILABLE_IOS`, meaning that it won’t compile as part of an iOS 8 extension. In order to facilitate `TMCache` usage inside extensions.

`TMCache` previously used `UIApplication` for two different functions:

* Wrapping work in background tasks, to ensure that it completes even if the user backgrounds the application
* Listening for `UIApplicationDidEnterBackgroundNotification` and `UIApplicationDidReceiveMemoryWarningNotification`, in order to perform some cleanup work

If you still want this behavior, it’s now up to you to implement this behavior in your application code. Thankfully, doing so is extremely straightforward:

## Background tasks

Create a class that conforms to `TMCacheBackgroundTaskManager`. Your implementation will likely look very much like this:

**Objective-C:**
```objc
@interface BackgroundTaskManager: NSObject <TMCacheBackgroundTaskManager>

@implementation BackgroundTaskManger

- (UIBackgroundTaskIdentifier)beginBackgroundTask {
    UIBackgroundTaskIdentifier taskID = UIBackgroundTaskInvalid;

    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:taskID];
    }];

    return taskID;
}

- (void)endBackgroundTask:(UIBackgroundTaskIdentifier)identifier {
    [[UIApplication sharedApplication] endBackgroundTask:identifier];
}

@end
```

**Swift:**
```swift
class BackgroundTaskManager: NSObject, TMCacheBackgroundTaskManager {
    private let application = UIApplication.sharedApplication()
    
    func beginBackgroundTask() -> UInt {
        let taskID = UIBackgroundTaskInvalid
        
        application.beginBackgroundTaskWithExpirationHandler {
            self.application.endBackgroundTask(taskID)
        }

        return UInt(taskID)
    }
    
    func endBackgroundTask(identifier: UInt) {
        application.endBackgroundTask(Int(identifier))
    }
}

```

Then, pass an instance of your class to the following `TMDiskCache` class method:

```objc
[TMDiskCache setBackgroundTaskManager:[[BackgroundTaskManager alloc] init]];
```

## Clean-up on memory warning/backgrounding notifications

`TMMemoryCache` has new public methods that can be called in the event of a memory warning or application backgrounding, in order to easily replicate `TMCache` 1.X.X behavior:

**Objective-C:**
```objc
[[NSNotificationCenter defaultCenter] addObserver:memoryCache
                                         selector:@selector(handleMemoryWarning)        
                                             name:UIApplicationDidReceiveMemoryWarningNotification     
                                           object:[UIApplication sharedApplication]];

[[NSNotificationCenter defaultCenter] addObserver:memoryCache
                                         selector:@selector(handleApplicationBackgrounding)        
                                             name:UIApplicationDidEnterBackgroundNotification     
                                           object:[UIApplication sharedApplication]];
```

**Swift:**
```swift
NSNotificationCenter.defaultCenter().addObserver(memoryCache, selector: "handleMemoryWarning", name: UIApplicationDidReceiveMemoryWarningNotification, object: UIApplication.sharedApplication())

NSNotificationCenter.defaultCenter().addObserver(memoryCache, selector: "handleApplicationBackgrounding", name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())
```

### 1.2.3 -- 2014 December 13 ###
         
- [fix] TMDiskCache/TMMemoryCache: import `UIKit` to facilitate Swift usage (thanks [digabriel](https://github.com/tumblr/TMCache/pull/57)!)       +### 1.2.3 -- 2015 April 27 ###
- [fix] TMDiskCache: add try catch to ensure an exception isn’t thrown if a file on disk is unable to be unarchived (thanks [leonskywalker](https://github.com/tumblr/TMCache/pull/62)!)       +
- [fix] TMDiskCache: create trash directory asynchronously to avoid race condition (thanks [napoapo77](https://github.com/tumblr/TMCache/pull/68)!)

### 1.2.2 -- 2014 October 6 ###

- [new] Remove deprecated `documentation` property from Podspec

### 1.2.1 -- 2013 July 28 ###

- [new] TMDiskCache: introduced concept of "trash" for rapid wipeouts
- [new] TMDiskCache: `nil` checks to prevent crashes
- [new] TMCache/TMDiskCache/TMMemoryCache: import Foundation to facilitate Swift usage

### 1.2.0 -- 2013 May 24 ###

- [new] TMDiskCache: added method `enumerateObjectsWithBlock:completionBlock:`
- [new] TMDiskCache: added method `enumerateObjectsWithBlock:`
- [new] TMDiskCache: added unit tests for the above
- [new] TMMemoryCache: added method `enumerateObjectsWithBlock:completionBlock:`
- [new] TMMemoryCache: added method `enumerateObjectsWithBlock:`
- [new] TMMemoryCache: added event block `didReceiveMemoryWarningBlock`
- [new] TMMemoryCache: added event block `didEnterBackgroundBlock`
- [new] TMMemoryCache: added boolean property `removeAllObjectsOnMemoryWarning`
- [new] TMMemoryCache: added boolean property `removeAllObjectsOnEnteringBackground`
- [new] TMMemoryCache: added unit tests for memory warning and app background blocks
- [del] TMCache: removed `cost` methods pending a solution for disk-based cost


### 1.1.2 -- 2013 May 13 ###

- [fix] TMCache: prevent `objectForKey:block:` from hitting the thread ceiling
- [new] TMCache: added a test to make sure we don't deadlock the queue


### 1.1.1 -- 2013 May 1 ###

- [fix] simplified appledoc arguments in podspec, updated doc script


### 1.1.0 -- 2013 April 29 ###

- [new] TMCache: added method `setObject:forKey:withCost:`
- [new] TMCache: documentation


### 1.0.3 -- 2013 April 27 ###

- [new] TMCache: added property `diskByteCount` (for convenience)
- [new] TMMemoryCache: `totalCost` now returned synchronously from queue
- [fix] TMMemoryCache: `totalCost` set to zero immediately after `removeAllObjects:`


### 1.0.2 -- 2013 April 26 ###

- [fix] TMCache: cache hits from memory will now update access time on disk
- [fix] TMDiskCache: set & remove methods now acquire a `UIBackgroundTaskIdentifier`
- [fix] TMDiskCache: will/didAddObject blocks actually get executed
- [fix] TMDiskCache: `trimToSize:` now correctly removes objects in order of size
- [fix] TMMemoryCache: `trimToCost:` now correctly removes objects in order of cost
- [new] TMDiskCache: added method `trimToSizeByDate:`
- [new] TMMemoryCache: added method `trimToCostByDate:`
- [new] TMDiskCache: added properties `willRemoveAllObjectsBlock` & `didRemoveAllObjectsBlock`
- [new] TMMemoryCache: added properties `willRemoveAllObjectsBlock` & `didRemoveAllObjectsBlock`
- [new] TMCache: added unit tests


### 1.0.1 -- 2013 April 23 ###

- added an optional "cost limit" to `TMMemoryCache`, including new properties and methods
- calling `[TMDiskCache trimToDate:]` with `[NSDate distantPast]` will now clear the cache
- calling `[TMDiskCache trimDiskToSize:]` will now remove files in order of access date
- setting the byte limit on `TMDiskCache` to 0 will no longer clear the cache (0 means no limit)
