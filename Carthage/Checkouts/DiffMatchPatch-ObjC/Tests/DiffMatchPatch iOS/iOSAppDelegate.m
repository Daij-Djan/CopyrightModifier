//
//  DMAppDelegate.m
//  DiffMatchPatch iOS
//
//  Created by Harry Jordan on 12/04/2013.
//
//

#import "iOSAppDelegate.h"
#import "TestUtilities.h"

@implementation iOSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UITextView *tv = [[UITextView alloc] initWithFrame:self.window.bounds];
    self.textView = tv;
    tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tv.editable = NO;
    
    UIViewController *vc = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    [vc.view addSubview:tv];
    
    self.window.rootViewController = vc;
    
    [self run];
    
    return YES;
}

- (void)run {
    NSMutableString *buf = [NSMutableString string];
    
    [buf appendString:@"\n\n"];

    NSString *text1FilePath = [[NSBundle mainBundle] pathForResource:@"Speedtest1" ofType:@"txt"];
    NSString *text2FilePath = [[NSBundle mainBundle] pathForResource:@"Speedtest2" ofType:@"txt"];
    
    NSString *text1 = diff_stringForFilePath(text1FilePath);
    NSString *text2 = diff_stringForFilePath(text2FilePath);
    
    [buf appendString:diff_measureTimeForDiff(text1, text2, @"Low quality diff -", FALSE)];
    [buf appendString:diff_measureTimeForDiff(text1, text2, @"High quality diff -", TRUE)];
    
    [buf appendString:@"\n\n"];
    
    [buf appendFormat:@"%@\n", printPerformanceTable(text1, text2, FALSE)];
    [buf appendFormat:@"%@\n", printPerformanceTable(text1, text2, TRUE)];
    
    self.textView.text = buf;
}

@end
