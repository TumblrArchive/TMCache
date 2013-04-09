# TMPettyCache #

## Hybrid in-memory/on-disk cache for iOS and OS X. ##

`TMPettyCache` is an asynchronous wrapper for [NSCache](https://developer.apple.com/library/ios/#documentation/Cocoa/Reference/NSCache_Class/Reference/Reference.html) with simultaneous persistence to disk. The in-memory and on-disk caches are configurable separately. Cached items are removed when the application receives a memory warning, goes into the background, or various optional limits are met. See the docs for more details.

## Installation  ##

### Manually ####

[Download the latest tag](https://github.com/tumblr/TMPettyCache/tags) and drag the `TMPettyCache` folder into your Xcode project. Install the docs by double clicking the `.docset` file.

### Git Submodule ###

    git submodule add git@github.com:tumblr/TMPettyCache.git
    git submodule update --init

### CocoaPods ###

Add [TMPettyCache](http://cocoapods.org/?q=name%3ATMPettyCache) to your `Podfile` and then run `pod install`.

## Example ##

Also see the [example](example/) included in the project.

    [[TMPettyCache sharedCache] setData:[@"value" dataUsingEncoding:NSUTF8StringEncoding]
                                 forKey:@"key"
                                  block:^(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL)
    {
        NSLog(@"data %p written to file at %@", data, fileURL);
    }];

    [[TMPettyCache sharedCache] dataForKey:@"key"
                                     block:^(TMPettyCache *cache, NSString *key, NSData *data, NSURL *fileURL)
    {
        NSLog(@"should be value: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }];

    [[TMPettyCache sharedCache] clearAllCachesSynchronously];

## Requirements ##

`TMPettyCache` requires iOS 5.0 or OS X 10.7 and greater.

## License ##

[Apache 2.0](LICENSE.TXT)

## Contact ##

[Justin Ouellette](mailto:jstn@tumblr.com)

## Copyright ##

2013 Tumblr, Inc.
