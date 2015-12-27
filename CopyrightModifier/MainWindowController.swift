//
//  MainWindowController.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 20/08/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSTextFieldDelegate, NSTextViewDelegate, PreviewWindowControllerDelegate {
    //InterfaceState
    private enum InterfaceState {
        case Main
        case Progress
        case Preview
    }
    private var shownState = InterfaceState.Main
    
    private let writer = FileWriter()
    private let generator = CopyrightGenerator()
    private var preparedGenerator: CopyrightGenerator {
        //setup writer
        generator.searchRecursively = (self.recursive.state == NSOnState)
        generator.includeHiddenFiles = (self.hiddenFiles.state == NSOnState)
        generator.validFileExtensions = self.patterns.stringValue.componentsSeparatedByString(";")
        generator.foldersToSkip = self.foldersToSkip.stringValue.componentsSeparatedByString(";")
        
        generator.findSCMAuthor = (self.authorOptions.selectedTag() == 1)
        generator.findSCMCreationDate = (self.dateOptions.selectedTag() == 1)
        if(self.fixedAuthor.stringValue.characters.count > 0) {
            generator.fixedAuthor = self.fixedAuthor.stringValue
        }
        generator.tryToMatchAuthor = (self.tryToMatchAuthor.state == NSOnState)
        generator.fixedDate = self.fixedDate.dateValue
        generator.extraCopyrightOwner = (self.ownerOptions.selectedTag()==2) ? self.fixedOwner.stringValue : nil
        generator.extraCopyrightYear = (self.yearOptions.selectedTag()==2) ? self.fixedYear.integerValue : nil //FIX
        generator.copyrightYearTillNow = (self.copyrightYearTillNow.state == NSOnState)
        
        generator.removeOldHeaderIfNeeded =  (self.removeOld.state == NSOnState)
        generator.addNewHeader = true
        
        generator.copyrightTemplate = self.newTemplate.string ?? "..."
        generator.licenseText = self.theLicenseText.string ?? "..."
                
        return generator
    }

    override func awakeFromNib() {
        //init the UI with the default template
        newTemplate.insertText(CopyrightGenerator.defaultCopyrightTemplate(), replacementRange: NSMakeRange(0, 0))

        //IB fails to set the font for some reason
        newTemplate.font = NSFont(name: "Menlo", size: 13)
        theLicenseText.font = NSFont(name: "Menlo", size: 13)
        
        if let cell = self.fixedAuthor.cell as? NSTextFieldCell {
            cell.placeholderString = NSUserName()
        }
        self.fixedDate.dateValue = NSDate()
        
        //fake url change
        changeLicenseURL(self.theLicenseURL)
    }
    
    private func setInterfaceState(interfaceState:InterfaceState, fileContents: Array<FileContent>?) {
        guard let view = self.window!.contentView
        else {
            fatalError("cant get contentView")
        }
        view.allEnabled = interfaceState == InterfaceState.Main
        
        if(interfaceState == InterfaceState.Progress) {
            if(shownState == InterfaceState.Preview) {
                self.window!.endSheet(self.previewWindowController.window!)
                self.previewWindowController.window!.orderOut(nil)
                self.previewWindowController.fileContents = nil
            }
            
            if(shownState != InterfaceState.Progress) {
                self.progressLabelDate.stringValue = "...";
                self.progressLabelAuthor.stringValue = "...";
                self.progressLabel.stringValue = "...";
                self.window!.beginSheet(self.progressSheet, completionHandler: nil)
                self.progressIndicator.startAnimation(nil)
            }
        }
        else if(interfaceState == InterfaceState.Preview) {
            if(shownState == InterfaceState.Progress) {
                self.progressIndicator.stopAnimation(nil)
                self.window!.endSheet(self.progressSheet)
                self.progressSheet.orderOut(nil)
            }
            
            if(shownState != InterfaceState.Preview) {
                self.previewWindowController.delegate = self
                self.previewWindowController.fileContents = fileContents
                self.window!.beginSheet(self.previewWindowController.window!, completionHandler: nil)
            }
        }
        else if(interfaceState == InterfaceState.Main) {
            if(shownState == InterfaceState.Progress) {
                self.progressIndicator.stopAnimation(nil)
                self.window!.endSheet(self.progressSheet)
                self.progressSheet.orderOut(nil)
            }
            else if(shownState == InterfaceState.Preview) {
                self.window!.endSheet(self.previewWindowController.window!)
                self.previewWindowController.window!.orderOut(nil)
                self.previewWindowController.fileContents = nil
            }
        }
        
        shownState = interfaceState
    }
    
    var processingEnabled: Bool {
        if self.path.stringValue.characters.count > 0 {
            return NSFileManager.defaultManager().fileExistsAtPath(self.path.stringValue)
        }
        
        return false
    }
    
    var pathIsFolder: Bool {
        if self.path.stringValue.characters.count > 0 {
            var isDir : ObjCBool = false
            if NSFileManager.defaultManager().fileExistsAtPath(self.path.stringValue, isDirectory: &isDir) {
                return isDir.boolValue
            }
        }
        
        return false
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        let textField = obj.object as! NSTextField?
        if(textField == self.theLicenseURL) {
            self.loadLicenseURL()
        }
        else {
            self.anyClick(obj.object!)
        }
    }

    func textDidChange(notification: NSNotification) {
        self.anyClick(notification.object!)
    }
    
    func loadLicenseURL() {
        self.theLicenseText.string = ""
        self.loadedLicenseURL = nil
        self.anyClick(self.theLicenseURL)

        let originalUrlString = self.theLicenseURL.stringValue
        if originalUrlString.characters.count > 0 {
            let urlString = self.theLicenseURL.stringValue
            let url = NSURL(string: urlString)
            if(url != nil) {
                let request = NSURLRequest(URL: url!)
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
                    if response is NSHTTPURLResponse && originalUrlString == self.theLicenseURL.stringValue {
                        let httpResponse = response as! NSHTTPURLResponse
                        if let d = data where httpResponse.statusCode == 200 {
                            if self.theLicenseURL.stringValue == urlString {
                                let str = NSString(data: d, encoding: NSUTF8StringEncoding)
                                self.theLicenseText.string = str as? String
                                self.loadedLicenseURL = url
                                self.anyClick(self.theLicenseURL)
                            }
                        }
                    }
                })
            }
        }
        else {
            self.theLicenseText.string = CopyrightGenerator.defaultLicenseText()
        }
    }
    
    // MARK: IB
    
    //folder or file
    @IBOutlet weak var path: NSTextField!
    
    //search options
    @IBOutlet weak var recursive: NSButton!
    @IBOutlet weak var hiddenFiles: NSButton!
    @IBOutlet weak var patterns: NSTextField!
    @IBOutlet weak var foldersToSkip: NSTextField!

    //change options
    @IBOutlet weak var authorOptions: NSMatrix!
    @IBOutlet weak var fixedAuthor: NSTextField!
    @IBOutlet weak var tryToMatchAuthor: NSButton!
    @IBOutlet weak var dateOptions: NSMatrix!
    @IBOutlet weak var fixedDate: NSDatePicker!
    
    @IBOutlet weak var ownerOptions: NSMatrix!
    @IBOutlet weak var fixedOwner: NSTextField!
    @IBOutlet weak var yearOptions: NSMatrix!
    @IBOutlet weak var fixedYear: NSTextField!
    @IBOutlet weak var copyrightYearTillNow: NSButton!
    @IBOutlet weak var licenseOptions: NSMatrix!
    @IBOutlet var theLicenseURL: NSTextField!
    private var loadedLicenseURL : NSURL?
    
    //the template to change
    @IBOutlet var theLicenseText: NSTextView!
    @IBOutlet var newTemplate: NSTextView!
    
    //operations
    @IBOutlet var backupOld: NSButton!
    @IBOutlet weak var removeOld: NSButton!
    
    //progress
    @IBOutlet var progressSheet: NSWindow!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var progressLabelAuthor: NSTextField!
    @IBOutlet weak var progressLabelDate: NSTextField!
    
    //preview panel
    @IBOutlet var previewWindowController: PreviewWindowController!
    
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
                    if !url.fileURL {
                        continue
                    }
                    
                    self.path.stringValue = url.path!
                    self.anyClick(sender)
                }
            }
        }
    }
    
    @IBAction func processPath(sender: AnyObject) {
        let url = NSURL(fileURLWithPath: self.path.stringValue, isDirectory: true)
        
        //disable UI
        self.setInterfaceState(InterfaceState.Progress, fileContents: nil)
        
        //output
        let myGenerator = self.preparedGenerator;
        myGenerator.maxiumNumberOfFiles = 0
        
        //go
        myGenerator.processURL(url, progressHandler: { (url, options) in
            self.progressLabel.stringValue = url.lastPathComponent!
            
            self.progressLabelAuthor.stringValue = options != nil ? options!.authorName : ""
            self.progressLabelDate.stringValue = options != nil ? options!.creationDateString : ""
            }, completionHandler: { (success, outputs, error) in
                var e : NSError?
                if !success {
                    e = error ?? NSError(domain: "CopyrightWriter", code: 1000, userInfo: [NSLocalizedDescriptionKey: "Unknown error processing \(url)"])
                }
                else if outputs.count == 0 {
                    e = NSError(domain: "CopyrightWriter", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No files were matched while processing \(url)"])
                }
                
                if e != nil {
                    let alert = NSAlert(error: e!)
                    alert.runModal()
                    self.setInterfaceState(InterfaceState.Main, fileContents: nil)
                }
                else {
                    self.setInterfaceState(InterfaceState.Preview, fileContents: outputs)
                }
        })
    }
    
    @IBAction func anyClick(sender: AnyObject) {
        self.willChangeValueForKey("processingEnabled")
        self.didChangeValueForKey("processingEnabled")
        self.willChangeValueForKey("pathIsFolder")
        self.didChangeValueForKey("pathIsFolder")
    }

    @IBAction func changeLicenseURL(sender: AnyObject) {
        var URLString = ""
        
        let row = self.licenseOptions.selectedRow
        let column = self.licenseOptions.selectedColumn

        if(column == 0) {
            //apache
            if(row == 0) {
                URLString = "http://licenses.pich.info/apache2.txt"
            }
            //gpl
            else if(row == 1) {
                URLString = "http://licenses.pich.info/gpl_v3.txt"
            }
            //mit
            else if(row == 2) {
                URLString = "http://licenses.pich.info/mit.txt"
            }
            //mozilla
            else if(row == 3) {
                URLString = "http://licenses.pich.info/mozilla_v2.txt"
            }
            //eclipse
            else if(row == 4) {
                URLString = "http://licenses.pich.info/epl.txt"
            }
        }
        else if(column == 1) {
            //bsd3
            if(row == 0) {
                URLString = "http://licenses.pich.info/bsd3.txt"
            }
            //bsd2
            else if(row == 1) {
                URLString = "http://licenses.pich.info/bsd2.txt"
            }
           //lgpl
            else if(row == 2) {
                URLString = "http://licenses.pich.info/lgpl_v3.txt"
            }
            //CD
            else if(row == 3) {
                URLString = "http://licenses.pich.info/cddl.txt"
            }
            //Custom...
            else if(row == 4) {
                //none ;)
            }
        }
        
        self.theLicenseURL.enabled = URLString.characters.count == 0
        self.theLicenseURL.stringValue = URLString
        loadLicenseURL()
    }
    
    @IBAction func cancelProcessing(sender: AnyObject) {
        self.preparedGenerator.cancelAllProcessing { () -> Void in
        }
    }
 
    //-
    
    func previewWindowController(controller:PreviewWindowController, didFinishSuccessfully:Bool) {
        if let contents = controller.checkedFileContents where didFinishSuccessfully {
            self.setInterfaceState(InterfaceState.Progress, fileContents: contents)
            self.writer.write(contents, progressHandler: { (url) -> Void in
                self.progressLabel.stringValue = url.lastPathComponent!
                }, completionHandler: { (ok, urls, error) -> Void in
                    self.setInterfaceState(InterfaceState.Main, fileContents: nil)
            })
        }
        else {
            self.setInterfaceState(InterfaceState.Main, fileContents: nil)
        }
    }
}