#import "TMExampleView.h"
#import "TMCache.h"

@implementation TMExampleView

- (void)setImageURL:(NSURL *)url
{
    _imageURL = url;
    
    NSString *key = [url absoluteString];

    [[TMCache sharedCache] dataForKey:key block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
        if (data) {
            NSLog(@"cache hit, %@", fileURL);
            self.image = [[UIImage alloc] initWithData:data];
            return;
        }
        
        NSLog(@"cache miss, requesting %@", url);

        [NSURLConnection sendAsynchronousRequest:[[NSURLRequest alloc] initWithURL:url]
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                   if (!data)
                                       return;

                                   self.image = [[UIImage alloc] initWithData:data];

                                   [[TMCache sharedCache] setData:data forKey:key block:^(TMCache *cache, NSString *key, NSData *data, NSURL *fileURL) {
                                       if (fileURL)
                                           NSLog(@"success, data written to %@", fileURL);
                                   }];
                               }];
    }];
}

@end
