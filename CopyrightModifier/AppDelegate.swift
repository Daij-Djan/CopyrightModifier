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
                windowController.path.stringValue = path
            }
        #endif
    }
 
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        #if !DEBUG
            let url = URL(fileURLWithPath: filename)
            loadOptionsFromFile(url)
            return true
        #endif
        
        return false
    }
    
    // MARK: load/save
    
    func loadOptionsFromFile(_ fileURL : URL) {
        let dict: NSDictionary
        do {
            let data = try Data(contentsOf: fileURL)
            dict = try JSONSerialization.jsonObject(with: data, options: []) as! NSDictionary
        }
        catch _ {
            print("failed to read saved data")
            return
        }
        
        let od = windowController.path.delegate
        windowController.path.delegate = nil
        
        //folder or file
        do {
            if let folderBookmarkData = Data(base64Encoded: dict["path"] as? String ?? "" ) {
                var isStale = false
                if let url = try URL(resolvingBookmarkData: folderBookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                    windowController.folderURL = url
                    windowController.path.stringValue = url.path
                }
            }
            if let gitBookmarkData = Data(base64Encoded: dict["gitPath"] as? String ?? "" ) {
                var isStale = false
                if let gitURL = try URL(resolvingBookmarkData: gitBookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                    windowController.gitURL = gitURL
                }
            }
        }
        catch _ {
            print("failed to load bookmarks")
        }
        
        //search options
        windowController.recursive.state = (dict["recursive"] as? Bool ?? false) ? NSOnState : NSOffState
        windowController.hiddenFiles.state = (dict["hiddenFiles"] as? Bool ?? false) ? NSOnState : NSOffState
        windowController.patterns.stringValue = dict["patterns"] as? String ?? ""
        windowController.foldersToSkip.stringValue = dict["foldersToSkip"] as? String ?? ""
        
        //change options
        windowController.authorOptions.selectCell(withTag: dict["authorOptions"] as? Int ?? 1)
        windowController.fixedAuthor.stringValue = dict["fixedAuthor"] as? String ?? ""
        windowController.dateOptions.selectCell(withTag: dict["dateOptions"] as? Int ?? 1)
        windowController.fixedDate.dateValue = Date(timeIntervalSince1970: dict["fixedDate"] as? Double ?? 0)
        
        windowController.ownerOptions.selectCell(withTag: dict["ownerOptions"] as? Int ?? 1)
        windowController.fixedOwner.stringValue = dict["fixedOwner"] as? String ?? ""
        windowController.yearOptions.selectCell(withTag: dict["yearOptions"] as? Int ?? 1)
        windowController.fixedYear.stringValue = dict["fixedYear"] as? String ?? ""
        windowController.copyrightYearTillNow.state = (dict["copyrightYearTillNow"] as? Bool ?? false) ? NSOnState : NSOffState
        windowController.licenseOptions.selectCell(withTag: dict["licenseOptions"] as? Int ?? 10)
        windowController.theLicenseURL.stringValue = dict["theLicenseURL"] as? String ?? ""
        let urlStr = dict["loadedLicenseURL"] as? String
        windowController.loadedLicenseURL = urlStr != nil ? URL(string: urlStr!) : nil
        
        //the template to change
        windowController.theLicenseText.string = dict["theLicenseText"] as? String ?? ""
        windowController.newTemplate.string = dict["newTemplate"] as? String ?? ""
        
        //operations
        windowController.backupOld.state = (dict["backupOld"] as? Bool ?? false) ? NSOnState : NSOffState
        windowController.writeLicenseFile.state = (dict["writeLicenseFile"] as? Bool ?? false) ? NSOnState : NSOffState
        windowController.removeOld.stringValue = dict["removeOld"] as? String ?? ""
        
        windowController.path.delegate = od
        
        windowController.touchedOptions = true
        windowController.updateUI()
    }
    
    func saveOptionsToFile(_ fileURL : URL) {
        let dict = NSMutableDictionary()

        //folder or file
        var bookmarkFolder: Data
        var bookmarkGit: Data
        do {
            if let url = windowController.folderURL {
                bookmarkFolder = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                dict["path"] = bookmarkFolder.base64EncodedString()
            }
            if let url = windowController.gitURL {
                bookmarkGit = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                dict["gitPath"] = bookmarkGit.base64EncodedString()
            }
        }
        catch _ {
            print("failed to save a bookmark")
        }
        
        //search options
        dict["recursive"] = windowController.recursive.state == NSOnState
        dict["hiddenFiles"] = windowController.hiddenFiles.state == NSOnState
        dict["patterns"] = windowController.patterns.stringValue
        dict["foldersToSkip"] = windowController.foldersToSkip.stringValue
        
        //change options
        dict["authorOptions"] = windowController.authorOptions.selectedTag()
        dict["fixedAuthor"] = windowController.fixedAuthor.stringValue
        dict["dateOptions"] = windowController.dateOptions.selectedTag()
        dict["fixedDate"] = windowController.fixedDate.dateValue.timeIntervalSince1970
        
        dict["ownerOptions"] = windowController.ownerOptions.selectedTag()
        dict["fixedOwner"] = windowController.fixedOwner.stringValue
        dict["yearOptions"] = windowController.yearOptions.selectedTag()
        dict["fixedYear"] = windowController.fixedYear.stringValue
        dict["copyrightYearTillNow"] = windowController.copyrightYearTillNow.state == NSOnState
        dict["licenseOptions"] = windowController.licenseOptions.selectedTag()
        dict["theLicenseURL"] = windowController.theLicenseURL.stringValue
        dict["loadedLicenseURL"] = windowController.loadedLicenseURL?.absoluteString ?? ""
        
        //the template to change
        dict["theLicenseText"] = windowController.theLicenseText.string ?? ""
        dict["newTemplate"] = windowController.newTemplate.string ?? ""
        
        //operations
        dict["backupOld"] = windowController.backupOld.state == NSOnState
        dict["writeLicenseFile"] = windowController.writeLicenseFile.state == NSOnState
        dict["removeOld"] = windowController.removeOld.stringValue
        print(dict)
        //write it
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            try data.write(to: fileURL)
        }
        catch _ {
            print("failed to write data")
        }
    }
    
    // MARK: IB

    @IBAction func load(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.title = "Load settings"
        panel.allowedFileTypes = ["crmconfig"]
        
        panel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let fileURL = panel.urls.first {
                    self.loadOptionsFromFile(fileURL)
                }
            }
        }
    }
    
    @IBAction func save(_ sender: AnyObject) {
        let panel = NSSavePanel()
        panel.title = "Save settings"
        panel.nameFieldStringValue = "Copyright Configuration"
        panel.allowedFileTypes = ["crmconfig"]
        panel.allowsOtherFileTypes = false
        panel.canCreateDirectories = true
        panel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                if let fileURL = panel.url {
                    self.saveOptionsToFile(fileURL)
                }
            }
        }
    }
    
    @IBOutlet var windowController: MainWindowController!
}
