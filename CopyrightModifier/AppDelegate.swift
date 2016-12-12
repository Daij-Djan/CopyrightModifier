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
        #if DEBUG
            let env = ProcessInfo.processInfo.environment
            if let path = env["UI_TESTING_PATH"] {
                if let main = windowController as? MainWindowController {
                    main.path.stringValue = path
                }
            }
        #endif
    }
 
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: IB
    
    @IBOutlet var windowController: NSWindowController!
}
