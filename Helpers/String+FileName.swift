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
            
        sanitizedString.replaceOccurrencesOfString("(", withString: "", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrencesOfString(")", withString:"", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrencesOfString("/", withString:"", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrencesOfString("\\", withString:"", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrencesOfString("&", withString:"and", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrencesOfString("?", withString:"", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrencesOfString("'", withString:"", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrencesOfString("\"", withString:"", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
        sanitizedString.replaceOccurrencesOfString(" ", withString:"-", options: NSStringCompareOptions(), range: NSMakeRange(0, sanitizedString.length))
            
        return sanitizedString as String
    }
}