#import "TMExampleView.h"
#import "TMCache.h"

@implementation TMExampleView

- (void)setImageURL:(NSURL *)url
{
    _imageURL = url;
    
    NSString *key = [url absoluteString];

    [[TMCache sharedCache] dataForKey:key block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        if (data) {
            self.image = [[UIImage alloc] initWithData:data];
            return;
        }

        [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url]
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   self.image = [[UIImage alloc] initWithData:data];
                                   [[TMCache sharedCache] setData:data forKey:key block:nil];
                               }];
    }];
}

@end
