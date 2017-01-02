//
//  PreviewWindowController
//  CoprightModifier
//
//  Created by Dominik Pich on 20/08/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Cocoa

protocol PreviewWindowControllerDelegate {
    func previewWindowController(_ controller:PreviewWindowController, didFinishSuccessfully:Bool)
}

class PreviewWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    var fileContents : Array<FileContent>? {
        didSet {
            var newFlags = [Bool]()
            if(fileContents != nil) {
                for fileContent in fileContents! {
                    newFlags.append(fileContent.modified)
                }
            }
            includeFlags = newFlags
            
            self.tableView.reloadData()
            self.textView.string =  ""
            if let contents = fileContents {
                if contents.count > 0 {
                    self.textView.string = contents[0].content
                }
            }
        }
    }
    var checkedFileContents : Array<FileContent>? {
        get {
            if(fileContents == nil ||
                fileContents!.count == 0 ||
                fileContents!.count != includeFlags.count) {
                return nil
            }
            
            var checked = [FileContent]()
            for i in 0...fileContents!.count-1 {
                if(includeFlags[i]) {
                    checked.append(fileContents![i])
                }
            }
            return checked.count > 0 ? checked : nil
        } 
    }
    fileprivate var includeFlags: [Bool]!
    
    var delegate: PreviewWindowControllerDelegate!

    override func awakeFromNib() {
        //IB fails to set the font for some reason
        self.textView.font = NSFont(name: "Menlo", size: 13)
    }
    
    //MARK: IB
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var textView: NSTextView!
    @IBOutlet var label: NSTextField!
    
    @IBAction func proceed(_ sender: AnyObject) {
        self.delegate.previewWindowController(self, didFinishSuccessfully: true)
    }
    
    @IBAction func cancel(_ sender: AnyObject) {
        self.delegate.previewWindowController(self, didFinishSuccessfully: false)
    }
    
    //MARK: DataSource & delegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileContents == nil ? 0 : fileContents!.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableColumn!.identifier == "included" {
            return includeFlags[row]
        }
        else if tableColumn!.identifier == "url" {
            let content = fileContents![row]
            return content.url.path
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if tableColumn?.identifier == "included" {
            let bool = object! as! NSNumber
            includeFlags[row] = bool.boolValue
            
            updateLabelFor(selectedRow: row)
        }
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = self.tableView.selectedRow
        
        self.textView.string = fileContents == nil || selectedRow < 0 ? "" : fileContents![selectedRow
            ].content
        updateLabelFor(selectedRow: selectedRow)
    }
    
    func updateLabelFor(selectedRow : Int) {
        guard(fileContents != nil && selectedRow >= 0) else {
            self.label.stringValue = "no file selected"
            self.label.backgroundColor = NSColor.gray
            return
        }
        
        var str1 = ""
        var str2 = ""
        
        let modified = fileContents![selectedRow].modified
        if modified {
            str1 = "file content was modified"
            
        }
        else {
            str1 = "edited file content is identical"
        }
        
        let willBeWritten = includeFlags[selectedRow]
        if willBeWritten {
            str2 = "file will be written to disk"
            
        }
        else {
            str2 = "file will NOT be written to disk"
        }
        
        self.label.stringValue = "\(str1)\n\(str2)"
        self.label.backgroundColor = willBeWritten ? NSColor.green : NSColor.red
    }
}
