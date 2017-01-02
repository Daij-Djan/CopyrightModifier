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
        if let URL = Bundle.main.url(forResource: "DefaultMinimalLicense", withExtension: "txt") {
            do {
                let txt = try NSString(contentsOf: URL, encoding: String.Encoding.utf8.rawValue)
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
    var fixedAuthor = NSFullUserName()
    var tryToMatchAuthor = true
    var findSCMCreationDate = true
    var fixedDate = Date()
    
    var extraCopyrightOwner: String? = nil
    var extraCopyrightYear: Int? = nil
    var copyrightYearTillNow = true
    
    //the template to change
    var licenseText: String = ""
    var copyrightTemplate: String = ""
    class func defaultCopyrightTemplate() -> String {
        //for starters, we use the template stored on disk
        if let URL = Bundle.main.url(forResource: "DefaultTemplate", withExtension: "txt") {
            do {
                let txt = try NSString(contentsOf: URL, encoding: String.Encoding.utf8.rawValue)
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
    var writeLicenseTextFile = false
    
    //MARK: private helpers
    fileprivate var cancelWriting = false
    
    fileprivate lazy var generatorQueue: DispatchQueue = {
        return DispatchQueue(label: "generator", attributes: [])
    }()
    
    fileprivate func dateStringForDate(_ date: Date) -> NSString {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.timeStyle = DateFormatter.Style.none
        return dateFormatter.string(from: date) as NSString
    }
    
    fileprivate func yearStringForDate(_ year: Int) -> NSString {
        if(self.copyrightYearTillNow) {
            let nowYear = (Calendar.current as NSCalendar).component(NSCalendar.Unit.year, from: Date())
            if(year != nowYear) {
                return NSString(format: "%d till %d", min(year, nowYear), max(year, nowYear))

            }
        }
        return NSString(format: "%d", year)
    }
    
    //MARK: processing
    
    func processURL(_ url: URL, progressHandler: @escaping (URL, CopyrightInformation?) -> Void, completionHandler: @escaping (Bool, Array<(FileContent)>, NSError?) -> Void) {
        self.generatorQueue.async {
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
            
            DispatchQueue.main.async {
                completionHandler(br, generatedOutputs, self.cancelWriting ? nil : error)
            }
        }
    }
    
    func cancelAllProcessing(_ completionHandler: @escaping () -> Void) {
        cancelWriting = true
        self.generatorQueue.async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.cancelWriting = false
                completionHandler()
            })
        })
    }
    
    //MARK: -
    
    fileprivate func processURL(_ url: URL, generatedOutputs: inout Array<(FileContent)>, progressHandler: @escaping (URL, CopyrightInformation?) -> Void) -> (Bool, NSError?) {
        //check SCM  and proceed
        let scmFileInfoOptions = FileManager.default.SCMStateOfFileAtURL(url)
        let fileInfoOptions = scmFileInfoOptions.union(.LOCAL)
        
        //read isDir from url
        var isDir: AnyObject?
        do {
            try (url as NSURL).getResourceValue(&isDir, forKey:URLResourceKey.isDirectoryKey)
        }
        catch {
            print("error reading isDir url key")
        }
        
        let isDirectory = isDir! as! NSNumber
        if !isDirectory.boolValue {
            if self.isValidExtension(url.pathExtension) {
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

            //check if we gotta create a license file
            if(self.writeLicenseTextFile && generatedOutputs.count > 0) {
                let licenseUrl = url.appendingPathComponent("license.txt")
                
                let res = self.writeLicenseFile(licenseUrl,
                                                fileInfoOptions: fileInfoOptions,
                                                generatedOutputs: &generatedOutputs)
                if res.0 == false {
                    return res
                }
            }
        }
        
        
        return (true, nil)
    }
    
    fileprivate func isValidExtension(_ ext:String) -> Bool {
        guard let validFileExtensions = self.validFileExtensions else {
            return true; //nil is ok
        }
        if validFileExtensions.count > 0 {
            for allowedExt in validFileExtensions {
                let trimmedExt = ext.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines);
                if(allowedExt == "*" || allowedExt.caseInsensitiveCompare(trimmedExt) == ComparisonResult.orderedSame) {
                    return true
                }
            }
            return false
        }
        return true
    }

    fileprivate func shouldVisitFolder(_ dirUrl:URL) -> Bool {
        let name = dirUrl.lastPathComponent.lowercased()
        
        //read IsPackageKey from url and skip packages
        var isPackage: AnyObject?
        do {
            try (dirUrl as NSURL).getResourceValue(&isPackage, forKey:URLResourceKey.isPackageKey)
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
        if( name.range(of: ".framework") != nil) {
            print("skip framework: \(name)")
            return false
        }
        
        //skip vendors
        if let foldersToSkip = self.foldersToSkip {
            for folderToSkip in foldersToSkip {
                if( name.caseInsensitiveCompare(folderToSkip) == .orderedSame ) {
                    return false
                }
            }
        }
        return true
    }

    fileprivate func processDirectory(_ dirUrl:URL, fileInfoOptions:FileInfoOptions, generatedOutputs: inout Array<(FileContent)>, progressHandler: @escaping (URL, CopyrightInformation?) -> Void) -> (Bool, NSError?) {

        //max
        if(self.maxiumNumberOfFiles > 0 && generatedOutputs.count >= self.maxiumNumberOfFiles) {
            return (true, nil)
        }
        
        if(!shouldVisitFolder(dirUrl)) {
            return (true, nil)
        }
        
        //report progress
//        print(dirUrl)
        DispatchQueue.main.async {
            progressHandler(dirUrl, nil)
        }
        
        //enumerate content
        var options = FileManager.DirectoryEnumerationOptions.skipsPackageDescendants
        options.formUnion(.skipsSubdirectoryDescendants) //we recurse manually
        if(self.includeHiddenFiles == false) {
            options.formUnion(.skipsHiddenFiles)
        }
        
        let keys = [URLResourceKey.isDirectoryKey, URLResourceKey.creationDateKey, URLResourceKey.isPackageKey]
        let enumerator = FileManager.default.enumerator(at: dirUrl, includingPropertiesForKeys: keys, options: options) { (url, error) -> Bool in
            print("failed to enumerate contents for \(url): \(error)")
            return false
        }
        if(enumerator == nil) {
            return (false, NSError(domain: "CopyRightWriter", code: 10, userInfo: [NSLocalizedDescriptionKey:"failed to enumerate contents for \(dirUrl)"]))
        }
        
        //process each enumerated child
        let array = enumerator!.allObjects as! [URL]
        for url in array {
            var isDir: AnyObject?
            do {
                try (url as NSURL).getResourceValue(&isDir, forKey:URLResourceKey.isDirectoryKey)
            }
            catch {
                print("error reading isDirectory url key for \(url)")
                return (false, NSError(domain: "CopyRightWriter", code: 11, userInfo: [NSLocalizedDescriptionKey:"error reading isDirectory url key for \(url)"]))
            }
            var creationDate: AnyObject?
            do {
                try (url as NSURL).getResourceValue(&creationDate, forKey:URLResourceKey.creationDateKey)
            }
            catch {
                print("error reading creationDate url key for \(url)")
                return (false, NSError(domain: "CopyRightWriter", code: 12, userInfo: [NSLocalizedDescriptionKey:"error reading creationDate url key for \(url)"]))
            }
            
            let isDirectory = isDir! as! NSNumber
            if !isDirectory.boolValue {
                if self.isValidExtension(url.pathExtension) {
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
    
    fileprivate func processFile(_ fileUrl:URL, fileInfoOptions:FileInfoOptions, generatedOutputs: inout Array<(FileContent)>, progressHandler: @escaping (URL, CopyrightInformation?) -> Void) -> (Bool, NSError?) {
        //check if canceled
        if(self.cancelWriting) {
            return (false, nil)
        }
        

        print("\(fileUrl)...")

        //begin
        let info = self.copyrightInformationForFile(fileUrl, fileInfoOptions: fileInfoOptions)
        
        //report progress
        DispatchQueue.main.async {
            progressHandler(fileUrl, info)
        }
        
        //read file content
        let content:NSMutableString
        do {
            content = try NSMutableString(contentsOf: fileUrl, encoding: String.Encoding.utf8.rawValue)
        }
        catch let anyError as NSError {
            return (false, NSError(domain: "CopyRightWriter", code: 20, userInfo: [NSLocalizedDescriptionKey:"error reading file content for \(fileUrl): \(anyError)"]))
        }
        
        //edit it if needed
        var modified = false
        autoreleasepool {
            modified = self.adaptContentIfNeeded(content, fileUrl: fileUrl, fileInfo: info)
        }
        
        //write it
        let val = FileContent(url:fileUrl,content:content as String, modified: modified)
        generatedOutputs.append(val)
        
        print("...done")

        //dont cahe history beyond a file
        GTRepository_cachedHistories.removeAll()

        return (true, nil)
    }
    
    
    func writeLicenseFile(_ licenseUrl:URL, fileInfoOptions:FileInfoOptions, generatedOutputs: inout Array<(FileContent)>) -> (Bool, NSError?) {
        //read file content
        var content:NSMutableString
        do {
            content = try NSMutableString(contentsOf: licenseUrl, encoding: String.Encoding.utf8.rawValue)
        }
        catch _ {
            content = ""
        }
        
        
        //new content
        let file = generatedOutputs.first!
        let fileInfo = self.copyrightInformationForFile(file.url, fileInfoOptions: fileInfoOptions)
        let licenseContent = self.generateCopyrightHeader(file.url.lastPathComponent, info: fileInfo)
        
        let modified = content as String != licenseContent
        let licenseFile = FileContent(url: licenseUrl, content: licenseContent, modified: modified)
        generatedOutputs.append(licenseFile)

        return (true, nil)
    }

    //
    
    func adaptContentIfNeeded(_ content:NSMutableString, fileUrl:URL, fileInfo:CopyrightInformation) -> Bool {
        var oldHeader = ""
        let newHeader = self.generateCopyrightHeader(fileUrl.lastPathComponent, info: fileInfo)
        
        //modification needed check
        if content.hasPrefix(newHeader) {
            return false
        }
        
        //RM OLD HEADER
        if(self.removeOldHeaderIfNeeded) {
            //find old header
            var inComment = false
            content.enumerateLines({ (l, stop) -> Void in
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
                
                stop.initialize(to: shouldStop)
            })
            
            //rm old header
            if oldHeader.characters.count > 0 {
                content.replaceOccurrences(of: oldHeader, with: "", options: NSString.CompareOptions.anchored, range: NSMakeRange(0, oldHeader.characters.count))
            }
        }
        
        //ADD NEW HEADER
        if self.addNewHeader {
            //prepend new header
            content.insert(newHeader, at: 0)
        }
        
        return self.removeOldHeaderIfNeeded || self.addNewHeader
    }

    func generateCopyrightHeader(_ fileName:String, info:CopyrightInformation) -> String {
        let header = NSMutableString(string: self.copyrightTemplate);
        
        header.replaceOccurrences(of: "${LICENSETEXT}", with: self.licenseText, options: NSString.CompareOptions(), range: NSMakeRange(0, header.length))
        
        header.replaceOccurrences(of: "${FILENAME}", with: fileName, options: NSString.CompareOptions(), range: NSMakeRange(0, header.length))
        header.replaceOccurrences(of: "${CREATIONDATE}", with: info.creationDateString, options: NSString.CompareOptions(), range: NSMakeRange(0, header.length))
        header.replaceOccurrences(of: "${AUTHOR}", with: info.authorName, options: NSString.CompareOptions(), range: NSMakeRange(0, header.length))
        header.replaceOccurrences(of: "${OWNER}", with: info.ownerName, options: NSString.CompareOptions(), range: NSMakeRange(0, header.length))
        header.replaceOccurrences(of: "${YEAR}", with: info.yearString, options: NSString.CompareOptions(), range: NSMakeRange(0, header.length))
        
        return header as String
    }

    // MARK:
    
    func copyrightInformationForFile(_ fileUrl:URL, fileInfoOptions:FileInfoOptions) -> CopyrightInformation {
        //get date
        var date: Date
        if(self.findSCMCreationDate) {
            date = FileManager.default.creationDateOfFileAtURL(fileUrl, options: fileInfoOptions)
        }
        else {
            date = self.fixedDate
        }
        let dateString = self.dateStringForDate(date);
        
        //year
        var year = (Calendar.current as NSCalendar).component(NSCalendar.Unit.year, from: date)
        if let customYear = self.extraCopyrightYear {
            year = customYear
        }
        let yearString = self.yearStringForDate(year)
        
        //get Author
        var author: NSString
        if(self.findSCMAuthor) {
            author = FileManager.default.authorOfFileAtURL(fileUrl, options: fileInfoOptions, matchToOSX:self.tryToMatchAuthor) as NSString
        }
        else {
            //this neednt be done here but it is ;)
            author = self.fixedAuthor as NSString
            if author as String == NSUserName() {
                author = NSFullUserName() as NSString
            }
        }
        
        //owner
        var owner = author
        if let customOwner = self.extraCopyrightOwner {
            //this neednt be done here but it is ;)
            owner = customOwner as NSString
            if owner as String == NSUserName() {
                owner = NSFullUserName() as NSString
            }
        }
        
        //return all info
        return CopyrightInformation(fileURL:fileUrl, creationDateString: dateString as String, yearString: yearString as String, authorName: author as String, ownerName: owner as String)
    }
}
