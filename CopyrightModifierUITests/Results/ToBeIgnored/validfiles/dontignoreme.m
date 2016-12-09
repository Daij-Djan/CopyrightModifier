/**
 @file      dontignoreme.m
 @author    Dominik Pich
 @date      12/19/13

Copyright (C) 2013 till 2016 Dominik Pich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#import "DDAppStoreInfo.h"

@implementation DDAppStoreInfo {
    NSDictionary *_info;
    DDImage *_smallArtwork;
}

- (NSString *)name {
    return _info[@"trackName"];
}

- (NSString *)description {
    return _info[@"description"];
}

- (DDImage *)smallArtwork {
    return _smallArtwork;
}

- (NSURL *)storeURL {
    return [NSURL URLWithString:_info[@"trackViewUrl"]];
}

- (NSDictionary *)json {
    return _info;
}

#pragma mark -

+ (void)appStoreInfoForID:(NSString *)idString completion:(void (^)(DDAppStoreInfo *appstoreInfo))completion {
    NSParameterAssert([idString hasPrefix:@"id"]);

    NSString *numericIDStr = [idString substringFromIndex:2];
    NSString *urlStr = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%@", numericIDStr];
    NSURL *url = [NSURL URLWithString:urlStr];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSArray *results = [dict objectForKey:@"results"];
        NSDictionary *result = [results objectAtIndex:0];
        
        //small icon
        NSString *imageUrlStr = [result objectForKey:@"artworkUrl60"];
        NSURL *artworkURL = [NSURL URLWithString:imageUrlStr];
        
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:artworkURL]
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            DDImage *artworkImage = [[DDImage alloc] initWithData:data];

            DDAppStoreInfo *storeInfo = [[DDAppStoreInfo alloc] init];
            storeInfo->_info = result;
            storeInfo->_smallArtwork = artworkImage;
            
            completion(storeInfo);
        }];
    }];
}

@end
