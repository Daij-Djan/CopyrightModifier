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
                for _ in 1...fileContents!.count {
                    newFlags.append(true)
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
        }
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = self.tableView.selectedRow
        self.textView.string = fileContents == nil || selectedRow < 0 ? "" : fileContents![selectedRow
            ].content
    }
}
