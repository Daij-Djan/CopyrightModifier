/*
 * Diff Match and Patch
 *
 * Copyright 2013 geheimwerk.de.
 * http://code.google.com/p/google-diff-match-patch/
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: jan@geheimwerk.de (Jan Weiß)
 */

#import "TestUtilities.h"
#import "DiffMatchPatch.h"

NSString * diff_stringForFilePath(NSString *aFilePath)
{
	NSString *absoluteFilePath;
    
	// FIXME: This does not work correctly with aliases: the alias file itself is read.
	// We can use the code from here to fix this:
	// http://cocoawithlove.com/2010/02/resolving-path-containing-mixture-of.html
	if ([aFilePath isAbsolutePath]) {
		absoluteFilePath = aFilePath;
	}
	else {
		absoluteFilePath = [[NSString pathWithComponents:
		                     [NSArray arrayWithObjects:
		                      [[NSFileManager defaultManager] currentDirectoryPath],
		                      aFilePath,
		                      nil]
                             ] stringByStandardizingPath];
	}
    
	NSURL *aURL = [NSURL fileURLWithPath:absoluteFilePath];
    
	return diff_stringForURL(aURL);
}

NSString * diff_stringForURL(NSURL *aURL)
{
	NSDictionary *documentAttributes;
	NSError *error;
	
	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithURL:aURL options:@{} documentAttributes:&documentAttributes error:&error];
	if (!attributedString) {
		NSLog(@"%@", error);
	}
    
	// For performance reasons, NSAttributedString’s -string method returns the current backing store of the attributed string object.
	// We need to make a copy or we will get a zombie soon after releasing attributedString below.
	NSString *string = [[attributedString string] copy];
	return string;
}

#pragma mark -

NSString *printPerformanceTable(NSString *text1, NSString *text2, BOOL highQuality) {
    NSMutableString *buf = [NSMutableString string];
    
    [buf appendFormat:@"   Performance Table: %s\n", highQuality ? "High Quality" : "Low Quality"];
    [buf appendFormat:@"  ------------------------------------------\n"];
    
    NSUInteger limit;
    for (int i = 8; i <= 24; i++) {
        limit = pow(2.0, i);
        if ( (limit > text1.length) || (limit > text2.length) ) {
            break;
        }
        
        NSString *description = [NSString stringWithFormat:@"%8lu characters, ", (unsigned long)limit];
        id str = diff_measureTimeForDiff([text1 substringToIndex:limit], [text2 substringToIndex:limit], description, highQuality);
        
        [buf appendFormat:@"%@\n", str];
    }
    
    return buf;
}


NSString *diff_measureTimeForDiff(NSString *text1, NSString *text2, NSString *description, BOOL highQuality)
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    NSArray *diffs = diff_diffsBetweenTextsWithOptions(text1, text2, highQuality, 0.0);
    NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
    
    id str;
    if(diffs.count > 0) {
        str = [NSString stringWithFormat:@"%s Elapsed time: %.4lf\n", [description UTF8String], (double)duration];
    } else {
        str = [NSString stringWithFormat:@"%s Failed to generate diffs\n", [description UTF8String]];
    }
    return str;
}
