//
//  AppDelegate.m
//  DiffMatchPatch Mac
//
//  Created by Harry Jordan on 12/04/2013.
//
//

#import "MacAppDelegate.h"
#import "TestUtilities.h"

@implementation MacAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
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
    
    self.textView.string = buf;
}

@end

