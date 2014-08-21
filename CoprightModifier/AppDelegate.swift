//
//  AppDelegate.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 20/08/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var path: NSTextField!
    @IBOutlet weak var recursive: NSButton!
    @IBOutlet weak var patterns: NSTextField!
    @IBOutlet weak var removeOld: NSButton!
    @IBOutlet weak var applyNewHeader: NSButton!
    @IBOutlet var newTemplate: NSTextView!
    @IBOutlet weak var box: NSBox!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var latestFile: NSTextField!
    
    override func awakeFromNib() {
//        path.stringValue = "/Users/name/Documents/Sources/project/"
    
        newTemplate.insertText("/**\n@file      ${FILENAME}\n@author    ${USERNAME}\n@date      ${CREATIONDATE}\n@copyright SomeCompany\n*/", replacementRange: NSMakeRange(0, 0))
    }
    
    @IBAction func openPath(sender: AnyObject) {
        if self.path.hidden {
            return
        }
        
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        
        panel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                for url in panel.URLs {
                    if !url.isFileURL {
                        continue
                    }
                    
                    self.path.stringValue = url.path
                }
            }
        }
    }
    
    @IBAction func processPath(sender: AnyObject) {
        let url = NSURL(fileURLWithPath: self.path.stringValue, isDirectory: true)
        let filePatterns:NSArray = self.patterns.stringValue.componentsSeparatedByString(";")

        for view in (self.window.contentView as NSView).subviews {
            (view as NSView).hidden = true
        }
        
        self.box.hidden = false
        self.progress.hidden = false
        self.latestFile.hidden = false
        
        self.progress.startAnimation(nil)
        self.latestFile.stringValue = url.lastPathComponent
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            var anyError: NSError?
            var isDir: AnyObject?
            var success = url.getResourceValue(&isDir, forKey:NSURLIsDirectoryKey, error:&anyError)
            if (!success) {
                println("error reading url key")
            }

            let isDirectory = isDir! as NSNumber
            if !isDirectory.boolValue {
                if filePatterns.count == 0 || filePatterns.containsObject("." + (url as NSURL).pathExtension) {
                    self.processFile(url)
                }
            }
            else {
                self.processDirectory(url, filePatterns:filePatterns)
            }
            
            self.latestFile.stringValue = url.lastPathComponent
            
            dispatch_async(dispatch_get_main_queue()) {
                for view in (self.window.contentView as NSView).subviews {
                    (view as NSView).hidden = false
                }

                self.progress.stopAnimation(nil)

                self.box.hidden = true
                self.progress.hidden = true
                self.latestFile.hidden = true
            }
        }
    }
    
    func processDirectory(dirUrl:NSURL, filePatterns:NSArray) {
        println(dirUrl)
        
        let keys = [NSURLIsDirectoryKey as AnyObject, NSURLCreationDateKey as AnyObject]
        let enumerator = NSFileManager.defaultManager().enumeratorAtURL(dirUrl, includingPropertiesForKeys: keys, options: NSDirectoryEnumerationOptions.SkipsPackageDescendants) { (url, error) -> Bool in
            println("failed (url)")
            return true
        }
        
        for url in enumerator.allObjects {
            dispatch_async(dispatch_get_main_queue()) {
                self.latestFile.stringValue = url.lastPathComponent
            }

            var anyError: NSError?
            var isDir: AnyObject?
            var success = url.getResourceValue(&isDir, forKey:NSURLIsDirectoryKey, error:&anyError)
            if (!success) {
                println("error reading url key")
                continue
            }
            var creationDate: AnyObject?
            success = url.getResourceValue(&creationDate, forKey:NSURLCreationDateKey, error:&anyError)
            if (!success) {
                println("error reading url key")
                continue
            }
            
            let isDirectory = isDir! as NSNumber
            if !isDirectory.boolValue {
                if filePatterns.count==0 || filePatterns.containsObject("." + (url as NSURL).pathExtension) {
                    processFile(url as NSURL)
                }
            }
        }
    }
    
    func processFile(fileUrl:NSURL) {
        println(fileUrl)
        
        var anyError: NSError?
        var content = NSMutableString(contentsOfURL: fileUrl, encoding: NSUTF8StringEncoding, error:&anyError)
        var oldHeader = ""
        
        if content.length==0 {
            println(anyError)
            return
        }

        //RM OLD HEADER
        if(self.removeOld.state == NSOnState) {
            //find old header
            var inComment = false
            content.enumerateLinesUsingBlock({ (l, stop) -> Void in
                let line = l as NSString
                var shouldStop: ObjCBool = true
                
                if line.hasPrefix("/*") {
                    inComment = true
                }
                
                if line.length==0 || line.hasPrefix("//") || inComment {
                    shouldStop = false
                    if countElements(oldHeader)>0 {
                        oldHeader += "\n"
                    }
                    oldHeader += line
                }
                
                if line.hasSuffix("*/") {
                    inComment = false
                }
                
                stop.initialize(shouldStop)
            })
        
            //rm old header
            if countElements(oldHeader)>0 {
                content.replaceOccurrencesOfString(oldHeader, withString: "", options: NSStringCompareOptions.AnchoredSearch, range: NSMakeRange(0, countElements(oldHeader)))
            }
        }
        
        //ADD NEW HEADER
        if self.applyNewHeader.state == NSOnState {
            if (self.newTemplate.string as NSString).length > 0 {
                //get file name
                let fileName = fileUrl.lastPathComponent
                var dateString:NSString = ""
                
                //get svn date
                let svnResult:NSString = DDTask.runTaskWithToolPath("/usr/bin/svn", andArguments: ["info", fileUrl.path], andErrorHandler: nil)
                let lines = svnResult.componentsSeparatedByString("\n")
                for line in lines as [NSString] {
                    if line.hasPrefix("Last Changed Date: ") {
                        let l = line.stringByReplacingOccurrencesOfString("Last Changed Date: ", withString: "")
                        let words = l.componentsSeparatedByString(" ")
                        dateString = words[0]
                        break
                    }
                }
                
                if dateString.length == 0 {
                    //get file date
                    var creationDate: AnyObject?
                    let success = fileUrl.getResourceValue(&creationDate, forKey:NSURLCreationDateKey, error:&anyError)
                    if !success {
                        println("error reading url key")
                        return
                    }
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
                    dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
                    dateString = dateFormatter.stringFromDate(creationDate as NSDate)
                }
                
                var userName = NSFullUserName()
                if !userName {
                    userName = NSUserName()
                }
                
                //prepend new header
                var header = NSMutableString(string: self.newTemplate.string)
                
                header.replaceOccurrencesOfString("${FILENAME}", withString: fileName, options: NSStringCompareOptions.convertFromNilLiteral(), range: NSMakeRange(0, header.length))
                header.replaceOccurrencesOfString("${CREATIONDATE}", withString: dateString, options: NSStringCompareOptions.convertFromNilLiteral(), range: NSMakeRange(0, header.length))
                header.replaceOccurrencesOfString("${USERNAME}", withString: userName, options: NSStringCompareOptions.convertFromNilLiteral(), range: NSMakeRange(0, header.length))
                
                content.insertString(header, atIndex: 0)
            }
        }
        
        //write it
        let br = content.writeToURL(fileUrl, atomically: false, encoding: NSUTF8StringEncoding, error: &anyError)
        if !br {
            println(anyError)
        }
    }
}

