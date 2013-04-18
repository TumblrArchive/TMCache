#import "TMExampleView.h"
#import "TMCache.h"

@implementation TMExampleView

- (void)setImageURL:(NSURL *)url
{
    _imageURL = url;
    
    [[TMCache sharedCache] objectForKey:@"image"
                                  block:^(TMCache *cache, NSString *key, id object) {
                                      UIImage *image = (UIImage *)object;
                                      NSLog(@"image scale: %f", image.scale);
                                      NSLog(@"disk cache usage: %d bytes", cache.diskCache.byteCount);
                                      
                                      NSArray *images = @[ image, image, image ];
                                      [[TMCache sharedCache] setObject:images forKey:@"images"];
                                      NSLog(@"three for the price of one: %d", [[[TMCache sharedCache] diskCache] byteCount]);
                                  }];
    
    [[TMCache sharedCache] objectForKey:[url absoluteString]
                                  block:^(TMCache *cache, NSString *key, id object) {
                                      if (object) {
                                          [self setImageOnMainThread:(UIImage *)object];
                                          return;
                                      }
                                    
                                      NSLog(@"cache miss, requesting %@", url);
                                      
                                      NSURLResponse *response = nil;
                                      NSURLRequest *request = [NSURLRequest requestWithURL:url];
                                      NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
                                      
                                      UIImage *image = [[UIImage alloc] initWithData:data scale:[[UIScreen mainScreen] scale]];
                                      [self setImageOnMainThread:image];

                                      [[TMCache sharedCache] setObject:image forKey:[url absoluteString]];
    }];
    
    
}

- (void)setImageOnMainThread:(UIImage *)image
{
    if (!image)
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"setting view image %@", NSStringFromCGSize(image.size));
        self.image = image;
    });
}

@end
