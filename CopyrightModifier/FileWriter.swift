//
//  Writer.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 22/11/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Cocoa
import ZipArchive

fileprivate let backupZipName = "_CRMBackup.zip"

class FileWriter {
    //operations
    var shouldDoBackup = false
    
    //MARK: private helpers
    fileprivate var cancelWriting = false
    
    fileprivate lazy var writerQueue: DispatchQueue = {
        return DispatchQueue(label: "writer", attributes: [])
    }()
    
    //MARK: processing
    
    func write(_ fileContents: Array<FileContent>, shouldDoBackupToFolder: URL?, progressHandler: @escaping (URL) -> Void, completionHandler: @escaping (Bool, Array<(URL)>, NSError?) -> Void) {
        self.writerQueue.async {
            var writtenFiles = Array<(URL)>()
            
            //zip all existing
            var ok = true
            if let folder = shouldDoBackupToFolder {
                let path = folder.appendingPathComponent(backupZipName).path
                let maybeContentPaths = fileContents.map({ (fileContent) -> String in
                    fileContent.url.path
                })
                let contentPaths = maybeContentPaths.filter({ (path) -> Bool in
                    return FileManager.default.fileExists(atPath: path)
                })
                ok = SSZipArchive.createZipFile(atPath: path, withFilesAtPaths: contentPaths as [Any])
            }
            
            //write it out
            var br = ok
            var error:NSError?
            if(ok) {
                let result = self.write(fileContents, writtenFiles:&writtenFiles, progressHandler: progressHandler)
                br = result.0
                error = result.1
            }

            //fix error if needed
            if(error == nil) {
                error = NSError(domain: "CopyRightWriter", code: 0, userInfo: [NSLocalizedDescriptionKey:"unkown error"])
            }
            
            //report success | callback on main thread
            DispatchQueue.main.async {
                completionHandler(br, writtenFiles, self.cancelWriting ? nil : error)
            }
        }
    }
    
    func cancelAllProcessing(_ completionHandler: @escaping () -> Void) {
        cancelWriting = true
        self.writerQueue.async(execute: { () -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.cancelWriting = false
                completionHandler()
            })
        })
    }
    //MARK: -
    
    fileprivate func write(_ fileContents: Array<FileContent>, writtenFiles: inout Array<(URL)>, progressHandler: @escaping (URL) -> Void) -> (Bool, NSError?) {
        for content in fileContents {
            if(self.cancelWriting) {
                return (false, nil)
            }

            //notify UI
            DispatchQueue.main.async(execute: { () -> Void in
                progressHandler(content.url as URL)
            })
            
            //write it
            do {
                try content.content.write(to: content.url as URL, atomically: false, encoding: String.Encoding.utf8)
            }
            catch let e as NSError {
                return (false, NSError(domain: "CopyRightWriter", code: 21, userInfo: [NSLocalizedDescriptionKey:"error writing file content to disk for \(content.url): \(e)"]))
            }
            
            writtenFiles.append(content.url as (URL))
        }
        
        return (true, nil)
    }
}
