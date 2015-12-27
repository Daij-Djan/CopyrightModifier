//
//  AppDelegate.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 20/08/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    override func awakeFromNib() {
        windowController.window!.center()
    }
 
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: IB
    
    @IBOutlet var windowController: NSWindowController!
}