//
//  CopyrightGenerator.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 22/11/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Cocoa

class CopyrightGenerator {
    //MARK: constants
    class func defaultLicenseText() -> String {
        //for starters, we use the template stored on disk
        if let URL = NSBundle.mainBundle().URLForResource("DefaultMinimalLicense", withExtension: "txt") {
            do {
                let txt = try NSString(contentsOfURL: URL, encoding: NSUTF8StringEncoding)
                return txt as String
            }
            catch {
                print("cant read default license text file")
            }
        }
        return ""
    }
    

    //MARK: options
    
    //search options
    var searchRecursively = true
    var includeHiddenFiles = false
    var validFileExtensions:[String]? = ["*"] //nil is ok
    var foldersToSkip:[String]?
    
    //change options
    var findSCMAuthor = true
    var fixedAuthor = NSUserName()
    var tryToMatchAuthor = true
    var findSCMCreationDate = true
    var fixedDate = NSDate()
    
    var extraCopyrightOwner: String? = nil
    var extraCopyrightYear: Int? = nil
    var copyrightYearTillNow = true
    
    //the template to change
    var licenseText: String = ""
    var copyrightTemplate: String = ""
    class func defaultCopyrightTemplate() -> String {
        //for starters, we use the template stored on disk
        if let URL = NSBundle.mainBundle().URLForResource("DefaultTemplate", withExtension: "txt") {
            do {
                let txt = try NSString(contentsOfURL: URL, encoding: NSUTF8StringEncoding)
                return txt as String
            }
            catch {
                print("cant read default copright text file")
            }
        }
        return ""
    }
    
    //operations
    var removeOldHeaderIfNeeded = true
    var addNewHeader = true
    var maxiumNumberOfFiles = 0
    
    //MARK: private helpers
    private var cancelWriting = false
    
    private lazy var generatorQueue: dispatch_queue_t = {
        return dispatch_queue_create("generator", DISPATCH_QUEUE_SERIAL)
    }()
    
    private func dateStringForDate(date: NSDate) -> NSString {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        return dateFormatter.stringFromDate(date)
    }
    
    private func yearStringForDate(year: Int) -> NSString {
        if(self.copyrightYearTillNow) {
            let nowYear = NSCalendar.currentCalendar().component(NSCalendarUnit.Year, fromDate: NSDate())
            if(year != nowYear) {
                return NSString(format: "%d till %d", min(year, nowYear), max(year, nowYear))

            }
        }
        return NSString(format: "%d", year)
    }
    
    //MARK: processing
    
    func processURL(url: NSURL, progressHandler: (NSURL, CopyrightInformation?) -> Void, completionHandler: (Bool, Array<(FileContent)>, NSError!) -> Void) {
        dispatch_async(self.generatorQueue) {
            var generatedOutputs = Array<(FileContent)>()
         
            let result = self.processURL(url,
                                         generatedOutputs:&generatedOutputs,
                                         progressHandler: progressHandler)

            //dont cache the repo for more than one run
            GTRepository_cachedRepositories.removeAll()
        
            //report success | callback on main thread
            let br = result.0
            var error = result.1
            if(error == nil) {
                error = NSError(domain: "CopyRightWriter", code: 0, userInfo: [NSLocalizedDescriptionKey:"unkown error"])
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(br, generatedOutputs, self.cancelWriting ? nil : error)
            }
        }
    }
    
    func cancelAllProcessing(completionHandler: () -> Void) {
        cancelWriting = true
        dispatch_async(self.generatorQueue, { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.cancelWriting = false
                completionHandler()
            })
        })
    }
    
    //MARK: -
    
    private func processURL(url: NSURL, inout generatedOutputs: Array<(FileContent)>, progressHandler: (NSURL, CopyrightInformation?) -> Void) -> (Bool, NSError?) {
        //check SCM  and proceed
        let scmFileInfoOptions = NSFileManager.defaultManager().SCMStateOfFileAtURL(url)
        let fileInfoOptions = scmFileInfoOptions.union(.LOCAL)
        
        //read isDir from url
        var isDir: AnyObject?
        do {
            try url.getResourceValue(&isDir, forKey:NSURLIsDirectoryKey)
        }
        catch {
            print("error reading isDir url key")
        }
        
        let isDirectory = isDir! as! NSNumber
        if !isDirectory.boolValue {
            if self.isValidExtension(url.pathExtension!) {
                let res = self.processFile(url,
                                           fileInfoOptions:fileInfoOptions,
                                           generatedOutputs:&generatedOutputs,
                                           progressHandler:progressHandler)

                if res.0 == false {
                    return res
                }
            }
        }
        else {
            let res = self.processDirectory(url,
                                           fileInfoOptions:fileInfoOptions,
                                           generatedOutputs:&generatedOutputs,
                                           progressHandler:progressHandler)
            if res.0 == false {
                return res
            }
        }
        
        return (true, nil)
    }
    
    private func isValidExtension(ext:String) -> Bool {
        guard let validFileExtensions = self.validFileExtensions else {
            return true; //nil is ok
        }
        if validFileExtensions.count > 0 {
            for allowedExt in validFileExtensions {
                let trimmedExt = ext.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet());
                if(allowedExt == "*" || allowedExt.caseInsensitiveCompare(trimmedExt) == NSComparisonResult.OrderedSame) {
                    return true
                }
            }
            return false
        }
        return true
    }

    private func shouldVisitFolder(dirUrl:NSURL) -> Bool {
        guard let name = dirUrl.lastPathComponent?.lowercaseString else {
            return false //?
        }
        
        //read IsPackageKey from url and skip packages
        var isPackage: AnyObject?
        do {
            try dirUrl.getResourceValue(&isPackage, forKey:NSURLIsPackageKey)
        }
        catch {
            print("error reading IsPackageKey url key")
        }
        let isPackageDir = isPackage! as! NSNumber
        if( isPackageDir.boolValue ) {
            print("skip package: \(name)")
            return false
        }
        
        //skip frameworks
        if( name.rangeOfString(".framework") != nil) {
            print("skip framework: \(name)")
            return false
        }
        
        //skip svendor
        //        print("go into \(dirUrl)")
        if let foldersToSkip = self.foldersToSkip {
            for folderToSkip in foldersToSkip {
                if( name.caseInsensitiveCompare(folderToSkip) == .OrderedSame ) {
                    return false
                }
            }
        }
        return true
    }

    private func processDirectory(dirUrl:NSURL, fileInfoOptions:FileInfoOptions, inout generatedOutputs: Array<(FileContent)>, progressHandler: (NSURL, CopyrightInformation?) -> Void) -> (Bool, NSError?) {

        //max
        if(self.maxiumNumberOfFiles > 0 && generatedOutputs.count >= self.maxiumNumberOfFiles) {
            return (true, nil)
        }
        
        if(!shouldVisitFolder(dirUrl)) {
            return (true, nil)
        }
        
        //report progress
//        print(dirUrl)
        dispatch_async(dispatch_get_main_queue()) {
            progressHandler(dirUrl, nil)
        }
        
        //enumerate content
        var options = NSDirectoryEnumerationOptions.SkipsPackageDescendants
        options.unionInPlace(.SkipsSubdirectoryDescendants) //we recurse manually
        if(self.includeHiddenFiles == false) {
            options.unionInPlace(.SkipsHiddenFiles)
        }
        
        let keys = [NSURLIsDirectoryKey, NSURLCreationDateKey, NSURLIsPackageKey]
        let enumerator = NSFileManager.defaultManager().enumeratorAtURL(dirUrl, includingPropertiesForKeys: keys, options: options) { (url, error) -> Bool in
            print("failed to enumerate contents for \(url): \(error)")
            return false
        }
        if(enumerator == nil) {
            return (false, NSError(domain: "CopyRightWriter", code: 10, userInfo: [NSLocalizedDescriptionKey:"failed to enumerate contents for \(dirUrl)"]))
        }
        
        //process each enumerated child
        let array = enumerator!.allObjects as! [NSURL]
        for url in array {
            var isDir: AnyObject?
            do {
                try url.getResourceValue(&isDir, forKey:NSURLIsDirectoryKey)
            }
            catch {
                print("error reading isDirectory url key for \(url)")
                return (false, NSError(domain: "CopyRightWriter", code: 11, userInfo: [NSLocalizedDescriptionKey:"error reading isDirectory url key for \(url)"]))
            }
            var creationDate: AnyObject?
            do {
                try url.getResourceValue(&creationDate, forKey:NSURLCreationDateKey)
            }
            catch {
                print("error reading creationDate url key for \(url)")
                return (false, NSError(domain: "CopyRightWriter", code: 12, userInfo: [NSLocalizedDescriptionKey:"error reading creationDate url key for \(url)"]))
            }
            
            let isDirectory = isDir! as! NSNumber
            if !isDirectory.boolValue {
                if self.isValidExtension(url.pathExtension!) {
                    let res = processFile(url,
                                          fileInfoOptions:fileInfoOptions,
                                          generatedOutputs:&generatedOutputs,
                                          progressHandler: progressHandler)
                    if res.0 == false {
                        return res
                    }
                    
                    //max
                    if(self.maxiumNumberOfFiles > 0 && generatedOutputs.count >= self.maxiumNumberOfFiles) {
                        return (true, nil)
                    }
                }
            }
            else {
                let res = self.processDirectory(url,
                    fileInfoOptions: fileInfoOptions,
                    generatedOutputs: &generatedOutputs,
                    progressHandler: progressHandler)
                if res.0 == false {
                    return res
                }
            }
        }
        
        return (true, nil)
    }
    
    private func processFile(fileUrl:NSURL, fileInfoOptions:FileInfoOptions, inout generatedOutputs: Array<(FileContent)>, progressHandler: (NSURL, CopyrightInformation?) -> Void) -> (Bool, NSError?) {
        //check if canceled
        if(self.cancelWriting) {
            return (false, nil)
        }
        

        print("\(fileUrl)...")

        //begin
        let info = self.copyrightInformationForFile(fileUrl, fileInfoOptions: fileInfoOptions)
        
        //report progress
        dispatch_async(dispatch_get_main_queue()) {
            progressHandler(fileUrl, info)
        }
        
        //read file content
        let content:NSMutableString
        do {
            content = try NSMutableString(contentsOfURL: fileUrl, encoding: NSUTF8StringEncoding)
        }
        catch let anyError as NSError {
            return (false, NSError(domain: "CopyRightWriter", code: 20, userInfo: [NSLocalizedDescriptionKey:"error reading file content for \(fileUrl): \(anyError)"]))
        }
        
        autoreleasepool {
            self.adaptContent(content, fileUrl: fileUrl, fileInfo: info)
        }
        
        //write it
        let val = FileContent(url:fileUrl,content:content as String)
        generatedOutputs.append(val)
        
        print("...done")

        //dont cahe history beyond a file
        GTRepository_cachedHistories.removeAll()

        return (true, nil)
    }
    
    func adaptContent(content:NSMutableString, fileUrl:NSURL, fileInfo:CopyrightInformation) {
        var oldHeader = ""
        
        //RM OLD HEADER
        if(self.removeOldHeaderIfNeeded) {
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
                    if oldHeader.characters.count > 0 {
                        oldHeader += "\n"
                    }
                    oldHeader += line as String
                }
                
                if line.hasSuffix("*/") {
                    inComment = false
                }
                
                stop.initialize(shouldStop)
            })
            
            //rm old header
            if oldHeader.characters.count > 0 {
                content.replaceOccurrencesOfString(oldHeader, withString: "", options: NSStringCompareOptions.AnchoredSearch, range: NSMakeRange(0, oldHeader.characters.count))
            }
        }
        
        //ADD NEW HEADER
        if self.addNewHeader {
            //prepend new header
            let header = self.generateCopyrightHeader(fileUrl.lastPathComponent!, info: fileInfo)
            content.insertString(header, atIndex: 0)
        }
    }

    func generateCopyrightHeader(fileName:String, info:CopyrightInformation) -> String {
        let header = NSMutableString(string: self.copyrightTemplate);
        
        header.replaceOccurrencesOfString("${LICENSETEXT}", withString: self.licenseText, options: NSStringCompareOptions(), range: NSMakeRange(0, header.length))
        
        header.replaceOccurrencesOfString("${FILENAME}", withString: fileName, options: NSStringCompareOptions(), range: NSMakeRange(0, header.length))
        header.replaceOccurrencesOfString("${CREATIONDATE}", withString: info.creationDateString, options: NSStringCompareOptions(), range: NSMakeRange(0, header.length))
        header.replaceOccurrencesOfString("${AUTHOR}", withString: info.authorName, options: NSStringCompareOptions(), range: NSMakeRange(0, header.length))
        header.replaceOccurrencesOfString("${OWNER}", withString: info.ownerName, options: NSStringCompareOptions(), range: NSMakeRange(0, header.length))
        header.replaceOccurrencesOfString("${YEAR}", withString: info.yearString, options: NSStringCompareOptions(), range: NSMakeRange(0, header.length))
        
        return header as String
    }

    // MARK:
    
    func copyrightInformationForFile(fileUrl:NSURL, fileInfoOptions:FileInfoOptions) -> CopyrightInformation {
        //get date
        var date: NSDate
        if(self.findSCMCreationDate) {
            date = NSFileManager.defaultManager().creationDateOfFileAtURL(fileUrl, options: fileInfoOptions)
        }
        else {
            date = self.fixedDate
        }
        let dateString = self.dateStringForDate(date);
        
        //year
        var year = NSCalendar.currentCalendar().component(NSCalendarUnit.Year, fromDate: date)
        if let customYear = self.extraCopyrightYear {
            year = customYear
        }
        let yearString = self.yearStringForDate(year)
        
        //get Author
        var author: NSString
        if(self.findSCMAuthor) {
            author = NSFileManager.defaultManager().authorOfFileAtURL(fileUrl, options: fileInfoOptions, matchToOSX:self.tryToMatchAuthor)
        }
        else {
            //this neednt be done here but it is ;)
            author = self.fixedAuthor
            if author == NSUserName() {
                author = NSFullUserName()
            }
        }
        
        //owner
        var owner = author
        if let customOwner = self.extraCopyrightOwner {
            //this neednt be done here but it is ;)
            owner = customOwner
            if owner == NSUserName() {
                owner = NSFullUserName()
            }
        }
        
        //return all info
        return CopyrightInformation(fileURL:fileUrl, creationDateString: dateString as String, yearString: yearString as String, authorName: author as String, ownerName: owner as String)
    }
}
