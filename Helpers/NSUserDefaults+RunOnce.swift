//
//  NSUserDefaults+RunOnce.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 03/04/15.
//  Copyright (c) 2015 Dominik Pich. All rights reserved.
//

import Foundation

extension NSUserDefaults {
    func runOnce(key:String, block:() -> Bool) -> Bool {
        let ranAlready = self.boolForKey(key)

        if(!ranAlready) {
            let runAgain = block()
            if(!runAgain) {
                self.setBool(true, forKey: key)
            }
        }
    
        return (ranAlready==false)
    }
}