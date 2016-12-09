//
//  NSView+allEnabled.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 14/03/15.
//  Copyright (c) 2015 Dominik Pich. All rights reserved.
//

import Cocoa

extension NSView {
    var allEnabled:Bool {
        get {
            for view in self.subviews {
                if view is NSControl {
                    if !(view as! NSControl).isEnabled {
                        return false
                    }
                }

                if !view.allEnabled {
                    return false
                }
            }
            return true
        }
        set {
            for view in self.subviews {
                if view is NSControl {
                    (view as! NSControl).isEnabled = newValue
                }

                view.allEnabled = newValue
            }
        }
    }
}
