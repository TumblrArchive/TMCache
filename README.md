# TMCache #

## Fast parallel object cache for iOS and OS X. ##

([TMCache](TMCache/TMCache.h)) is an asynchronous key/value store comprised of two self-similar stores, one in memory ([TMMemoryCache](TMCache/TMMemoryCache.h)) and one on disk ([TMDiskCache](TMCache/TMDiskCache.h)). It's designed for temporarily persisting objects that are expensive to reproduce, e.g. downloaded data or the products of long computation.







__TMCache__ is a queue-based key/value store with auto removal, similar to `NSCache` with the addition of persistence to disk. It's great for transient data that's expensive to reproduce, like downloaded images or the products of long computation.

__TMCache__ is comprised of three classes that can be used separately or together: a memory cache ([TMMemoryCache](TMCache/TMMemoryCache.h)), a disk cache ([TMDiskCache](TMCache/TMDiskCache.h)), and a parallel cache ([TMCache](TMCache/TMCache.h)) that coordinates the efforts of the two. It's backed by ARC and GCD, 100% asynchronous, lockless, and safe to access from any thread or queue at any time. Synchronous variations of all methods are provided for your convenience. See the docs for more information.

### TMMemoryCache ###

- cache reads are concurrent while cache writes are safely serialized
- able to clear itself periodically based on a configurable object age limit
- clears itself when the app backgrounds or receives a memory warning (iOS)
- trimmable based on the date of last object access

### TMDiskCache ###

- accepts any object conforming to the `NSCoding` protocol, including many in UIKit
- also accepts collection objects thereof, e.g. an `NSArray` of `UIImage`
- all instances share the same serial queue for performance and to prevent contention
- able to clear itself periodically based on configurable age and/or byte limit
- trimmable to any size or date with automatic completion in app background (iOS)

### TMCache ###

- contains one `TMMemoryCache` and one `TMDiskCache`, each publicly accessible
  and usable independently
- reads and writes to both simultaneously, automatically repopulating the memory
  cache from disk when it encounters a miss
- fast reads and writes to memory won't get blocked by slow reads and writes to disk

## Installation  ##

### Manually ####

[Download the latest tag](https://github.com/tumblr/TMCache/tags) and drag the `TMCache` folder into your Xcode project.

Install the docs by double clicking the `.docset` file.

### Git Submodule ###

    git submodule add https://github.com/tumblr/TMCache.git
    git submodule update --init

### CocoaPods ###

Add [TMCache](http://cocoapods.org/?q=name%3ATMCache) to your `Podfile` and run `pod install`.

## Example ##

    NSURL *imageURL = [NSURL URLWithString:@"http://upload.wikimedia.org/wikipedia/commons/6/62/Sts114_033.jpg"];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:imageURL]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [[TMCache sharedCache] setObject:[[UIImage alloc] initWithData:data]
                                                         forKey:[imageURL absoluteString]
                                                          block:^(TMCache *cache, NSString *key, id object) {
                                                                    NSURL *fileURL = [[cache diskCache] fileURLForKey:key];
                                                                    NSLog(@"success, data written to %@", [fileURL path]);
                                                                    NSLog(@"total disk use: %d bytes", [[cache diskCache] byteCount]);
                                                                }];
                           }];

## Requirements ##

__TMCache__ requires iOS 5.0 or OS X 10.7 and greater.

## Contact ##

[Justin Ouellette](mailto:jstn@tumblr.com)

## License ##

Copyright 2013 Tumblr, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. [See the License](LICENSE.txt) for the specific language governing permissions and limitations under the License.
