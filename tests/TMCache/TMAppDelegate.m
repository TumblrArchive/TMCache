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
    
    return YES;
}

@end
