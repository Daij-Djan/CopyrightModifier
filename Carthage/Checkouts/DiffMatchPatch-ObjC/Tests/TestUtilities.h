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


#import <Foundation/Foundation.h>

NSString * diff_stringForFilePath(NSString *aFilePath);
NSString * diff_stringForURL(NSURL *aURL);

NSString *printPerformanceTable(NSString *text1, NSString *text2, BOOL highQuality);
NSString *diff_measureTimeForDiff(NSString *text1, NSString *text2, NSString *description, BOOL highQuality);
