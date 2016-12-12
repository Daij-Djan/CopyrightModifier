//
//  MainWindowController.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 20/08/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Cocoa
import ObjectiveGit

class MainWindowController: NSWindowController, NSTextFieldDelegate, NSTextViewDelegate, PreviewWindowControllerDelegate {
    //InterfaceState
    fileprivate enum InterfaceState {
        case main
        case progress
        case preview
    }
    fileprivate var shownState = InterfaceState.main
    
    fileprivate let writer = FileWriter()
    fileprivate let generator = CopyrightGenerator()
    fileprivate var preparedGenerator: CopyrightGenerator {
        //setup writer
        generator.searchRecursively = (self.recursive.state == NSOnState)
        generator.includeHiddenFiles = (self.hiddenFiles.state == NSOnState)
        generator.validFileExtensions = self.patterns.stringValue.components(separatedBy: ";")
        generator.foldersToSkip = self.foldersToSkip.stringValue.components(separatedBy: ";")
        
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
        //IB fails to set the font for some reason
        newTemplate.font = NSFont(name: "Menlo", size: 13)
        theLicenseText.font = NSFont(name: "Menlo", size: 13)
        
        //set default values
        if let cell = self.fixedAuthor.cell as? NSTextFieldCell {
            cell.placeholderString = NSUserName()
            cell.stringValue = NSUserName()
        }
        self.fixedDate.dateValue = Date()
        
        //init the UI with the default template
        //and trigger a fake click event
        newTemplate.insertText(CopyrightGenerator.defaultCopyrightTemplate(), replacementRange: NSMakeRange(0, 0))

        //fake url change
        changeLicenseURL(self.theLicenseURL)
    }
    
    fileprivate func setInterfaceState(_ interfaceState:InterfaceState, fileContents: Array<FileContent>?) {
        guard let view = self.window!.contentView
        else {
            fatalError("cant get contentView")
        }
        view.allEnabled = interfaceState == InterfaceState.main
        
        if(interfaceState == InterfaceState.progress) {
            if(shownState == InterfaceState.preview) {
                self.window!.endSheet(self.previewWindowController.window!)
                self.previewWindowController.window!.orderOut(nil)
                self.previewWindowController.fileContents = nil
            }
            
            if(shownState != InterfaceState.progress) {
                self.progressLabelDate.stringValue = "...";
                self.progressLabelAuthor.stringValue = "...";
                self.progressLabel.stringValue = "...";
                self.window!.beginSheet(self.progressSheet, completionHandler: nil)
                self.progressIndicator.startAnimation(nil)
            }
        }
        else if(interfaceState == InterfaceState.preview) {
            if(shownState == InterfaceState.progress) {
                self.progressIndicator.stopAnimation(nil)
                self.window!.endSheet(self.progressSheet)
                self.progressSheet.orderOut(nil)
            }
            
            if(shownState != InterfaceState.preview) {
                self.previewWindowController.delegate = self
                self.previewWindowController.fileContents = fileContents
                self.window!.beginSheet(self.previewWindowController.window!, completionHandler: nil)
            }
        }
        else if(interfaceState == InterfaceState.main) {
            if(shownState == InterfaceState.progress) {
                self.progressIndicator.stopAnimation(nil)
                self.window!.endSheet(self.progressSheet)
                self.progressSheet.orderOut(nil)
            }
            else if(shownState == InterfaceState.preview) {
                self.window!.endSheet(self.previewWindowController.window!)
                self.previewWindowController.window!.orderOut(nil)
                self.previewWindowController.fileContents = nil
            }
        }
        
        shownState = interfaceState
    }
    
    var gitRepoFound: Bool {
        if self.path.stringValue.characters.count > 0 {
            return GTRepository.findRepositoryWithURL(URL(fileURLWithPath: self.path.stringValue)) != nil
        }
        
        return false
    }
    
    var processingEnabled: Bool {
        if self.path.stringValue.characters.count > 0 {
            return FileManager.default.fileExists(atPath: self.path.stringValue)
        }
        
        return false
    }
    
    var pathIsFolder: Bool {
        if self.path.stringValue.characters.count > 0 {
            var isDir : ObjCBool = false
            if FileManager.default.fileExists(atPath: self.path.stringValue, isDirectory: &isDir) {
                return isDir.boolValue
            }
        }
        
        return false
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField?
        if(textField == self.theLicenseURL) {
            self.loadLicenseURL()
        }
        else {
            self.anyClick(obj.object! as AnyObject)
        }
    }

    func textDidChange(_ notification: Notification) {
        self.anyClick(notification.object! as AnyObject)
    }
    
    func loadLicenseURL() {
        self.theLicenseText.string = ""
        self.loadedLicenseURL = nil
        self.anyClick(self.theLicenseURL)

        let originalUrlString = self.theLicenseURL.stringValue
        if originalUrlString.characters.count > 0 {
            let urlString = self.theLicenseURL.stringValue
            let url = URL(string: urlString)
            if(url != nil) {
                let request = URLRequest(url: url!)
                NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main, completionHandler: { (response, data, error) -> Void in
                    if response is HTTPURLResponse && originalUrlString == self.theLicenseURL.stringValue {
                        let httpResponse = response as! HTTPURLResponse
                        if let d = data, httpResponse.statusCode == 200 {
                            let str = NSString(data: d, encoding: String.Encoding.utf8.rawValue)
                            DispatchQueue.main.async {
                                if self.theLicenseURL.stringValue == urlString {
                                    self.theLicenseText.string = str as? String
                                    self.loadedLicenseURL = url
                                    self.anyClick(self.theLicenseURL)
                                }
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
    fileprivate var loadedLicenseURL : URL?
    
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
    
    @IBAction func openPath(_ sender: AnyObject) {
        if self.path.isHidden {
            return
        }
        
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        
        panel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                for fileURL in panel.urls {
                    if !fileURL.isFileURL {
                        continue
                    }
                    
                    if GTRepository.findRepositoryWithURL(fileURL) == nil {
                        let alert = NSAlert()
                        alert.messageText = "The chosen file/folder is not a git repository and some advanced functionality wont be available. If this file/folder is part of a git repository though, please select the repository root now.";
                        alert.addButton(withTitle: "Select GIT Repo")
                        alert.addButton(withTitle: "Proceed without")
                        let answer = alert.runModal()
                        if answer == NSAlertFirstButtonReturn {
                            self.openGitURLForSender(sender, path:fileURL.path)
                            return
                        }
                    }

                    self.path.stringValue = fileURL.path
                    self.anyClick(sender)
                }
            }
        }
    }
    
    func openGitURLForSender(_ sender: AnyObject, path: String) {
        if self.path.isHidden {
            return
        }
        
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canCreateDirectories = false
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        panel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                for fileURL in panel.urls {
                    if !fileURL.isFileURL {
                        continue
                    }
                    
                    if GTRepository.findRepositoryWithURL(fileURL) == nil {
                        let alert = NSAlert()
                        alert.messageText = "The chosen folder is still not a valid git repository and some advanced functionality wont be available. To retry, browse for the file/folder again.";
                        alert.runModal()
                    }
                    
                    self.path.stringValue = fileURL.path
                    self.anyClick(sender)
                }
            }
        }
    }
    
    @IBAction func processPath(_ sender: AnyObject) {
        //grab responder state
        self.window?.makeFirstResponder(sender as? NSResponder)
        
        let url = URL(fileURLWithPath: self.path.stringValue)
        
        //disable UI
        self.setInterfaceState(InterfaceState.progress, fileContents: nil)
        
        //output
        let myGenerator = self.preparedGenerator;
        myGenerator.maxiumNumberOfFiles = 0
        
        //go
        myGenerator.processURL(url, progressHandler: { (url, options) in
            self.progressLabel.stringValue = url.lastPathComponent
            
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
                    self.setInterfaceState(InterfaceState.main, fileContents: nil)
                }
                else {
                    self.setInterfaceState(InterfaceState.preview, fileContents: outputs)
                }
        })
    }
    
    @IBAction func anyClick(_ sender: AnyObject) {
        self.willChangeValue(forKey: "gitRepoFound")
        self.didChangeValue(forKey: "gitRepoFound")
        self.willChangeValue(forKey: "processingEnabled")
        self.didChangeValue(forKey: "processingEnabled")
        self.willChangeValue(forKey: "pathIsFolder")
        self.didChangeValue(forKey: "pathIsFolder")
    }

    @IBAction func changeLicenseURL(_ sender: AnyObject) {
        var URLString = ""
         
        let row = self.licenseOptions.selectedRow
        let column = self.licenseOptions.selectedColumn

        if(column == 0) {
            //apache
            if(row == 0) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/apache2.txt"
            }
            //gpl
            else if(row == 1) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/gpl_v3.txt"
            }
            //mit
            else if(row == 2) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/mit.txt"
            }
            //mozilla
            else if(row == 3) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/mozilla_v2.txt"
            }
            //eclipse
            else if(row == 4) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/epl.txt"
            }
        }
        else if(column == 1) {
            //bsd3
            if(row == 0) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/bsd3.txt"
            }
            //bsd2
            else if(row == 1) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/bsd2.txt"
            }
           //lgpl
            else if(row == 2) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/lgpl_v3.txt"
            }
            //CD
            else if(row == 3) {
                URLString = "https://www.pich.info/apps/copyrightmodifier/licenses/cddl.txt"
            } 
            //Custom...
            else if(row == 4) {
                //none ;)
            }
        }
        
        self.theLicenseURL.isEnabled = URLString.characters.count == 0
        self.theLicenseURL.stringValue = URLString
        loadLicenseURL()
    }
    
    @IBAction func cancelProcessing(_ sender: AnyObject) {
        self.preparedGenerator.cancelAllProcessing { () -> Void in
        }
    }
 
    //-
    
    func previewWindowController(_ controller:PreviewWindowController, didFinishSuccessfully:Bool) {
        if let contents = controller.checkedFileContents, didFinishSuccessfully {
            self.setInterfaceState(InterfaceState.progress, fileContents: contents)
            self.writer.write(contents, progressHandler: { (url) -> Void in
                self.progressLabel.stringValue = url.lastPathComponent
                }, completionHandler: { (ok, urls, error) -> Void in
                    self.setInterfaceState(InterfaceState.main, fileContents: nil)
            })
        }
        else {
            self.setInterfaceState(InterfaceState.main, fileContents: nil)
        }
    }
}
