//
//  String+fileName.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 04/09/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Foundation

extension String {
    var fileName:String {
        //poor sanitasation
        let string = self as NSString;
        let sanitizedString = string.mutableCopy() as! NSMutableString
            
        sanitizedString.replaceOccurrences(of: "(", with: "", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrences(of: ")", with:"", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrences(of: "/", with:"", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrences(of: "\\", with:"", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrences(of: "&", with:"and", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrences(of: "?", with:"", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrences(of: "'", with:"", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrences(of: "\"", with:"", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrences(of: " ", with:"-", options: NSString.CompareOptions(), range: NSMakeRange(0, sanitizedString.length))
            
        return sanitizedString as String
    }
}
