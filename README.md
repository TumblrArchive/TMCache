# TMPettyCache #

## Hybrid in-memory/on-disk cache for iOS and OS X. ##

`TMPettyCache` is an asynchronous wrapper for [NSCache](https://developer.apple.com/library/ios/#documentation/Cocoa/Reference/NSCache_Class/Reference/Reference.html) with simultaneous persistence to disk. The in-memory and on-disk caches are configurable separately. Cached items are removed when the application receives a memory warning, goes into the background, or various optional limits are met. See the docs for more details.

## Installation  ##

### Manually ####

[Download the latest tag](https://github.com/tumblr/TMPettyCache/tags) and drag the `TMPettyCache` folder into your Xcode project.

Install the docs by double clicking the `.docset` file.

### Git Submodule ###

    git submodule add https://github.com/tumblr/TMPettyCache.git
    git submodule update --init

### CocoaPods ###

Add [TMPettyCache](http://cocoapods.org/?q=name%3ATMPettyCache) to your `Podfile` and run `pod install`.

## Example ##

Also see the [example](example/) included in the project.

    NSURL *imageURL = [NSURL URLWithString:@"http://upload.wikimedia.org/wikipedia/commons/6/62/Sts114_033.jpg"];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:imageURL]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               [[TMPettyCache sharedCache] setData:data
                                                            forKey:[imageURL absoluteString]
                                                             block:^(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
                                                                 NSLog(@"%@ wrote %d bytes to %@", cache, [data length], fileURL);
                                                             }];
                           }];

## Requirements ##

`TMPettyCache` requires iOS 5.0 or OS X 10.7 and greater.

## Contact ##

[Justin Ouellette](mailto:jstn@tumblr.com)

## License ##

Copyright 2013 Tumblr, Inc.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the [License](LICENSE.TXT) for the specific language governing permissions and limitations under the License.
