#import "TMExampleView.h"
#import "TMCache.h"

@implementation TMExampleView

- (void)setImageURL:(NSURL *)url
{
    _imageURL = url;
    
    [[TMCache sharedCache] objectForKey:[url absoluteString] block:^(TMCache *cache, NSString *key, id object) {
        if (object) {
            UIImage *image = (UIImage *)object;
            
            NSLog(@"cache hit: %@", image);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.image = image;
            });

            return;
        }
        
        NSLog(@"cache miss, requesting %@", url);
        
        [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url]
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if (![data length])
                                       return;

                                   self.image = [[UIImage alloc] initWithData:data scale:[[UIScreen mainScreen] scale]];
                                   
                                   [[TMCache sharedCache] setObject:self.image
                                                             forKey:key
                                                              block:^(TMCache *cache, NSString *key, id object) {
                                                                        NSURL *fileURL = [[cache diskCache] fileURLForKey:key];
                                                                        NSLog(@"success, object written to %@", [fileURL path]);
                                                                        NSLog(@"total disk use: %d bytes", [[cache diskCache] byteCount]);
                                                                    }];
                               }];
    }];
}

@end
