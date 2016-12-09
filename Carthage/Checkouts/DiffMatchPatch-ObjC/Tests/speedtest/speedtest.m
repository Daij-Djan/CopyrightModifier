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
 * Author: fraser@google.com (Neil Fraser)
 * ObjC port: jan@geheimwerk.de (Jan Weiß)
 */

#import <Foundation/Foundation.h>
#import "TestUtilities.h"

int main(int argc, const char *argv[])
{
	@autoreleasepool {
		NSString *text1FilePath = @"Speedtest1.txt";
		NSString *text2FilePath = @"Speedtest2.txt";
		
		NSArray *cliArguments = [[NSProcessInfo processInfo] arguments];
		
		if ([cliArguments count] == 3) {
			text1FilePath = [cliArguments objectAtIndex:1];
			text2FilePath = [cliArguments objectAtIndex:2];
		}
		
		NSString *text1 = diff_stringForFilePath(text1FilePath);
		NSString *text2 = diff_stringForFilePath(text2FilePath);
		
		printf("%s", diff_measureTimeForDiff(text1, text2, @"Low quality diff -", FALSE).UTF8String);
		printf("%s", diff_measureTimeForDiff(text1, text2, @"High quality diff -", TRUE).UTF8String);
		
		printf("\n\n");
		
		printf("%s\n", printPerformanceTable(text1, text2, FALSE).UTF8String);
		printf("%s\n", printPerformanceTable(text1, text2, TRUE).UTF8String);
	}
	
	return 0;
}