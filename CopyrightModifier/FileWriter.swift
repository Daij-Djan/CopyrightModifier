//
//  Writer.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 22/11/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Cocoa

class FileWriter {
    //MARK: constants
    class func backupFolderBaseName() -> String { return "__CRMBackup" }
    
    //operations
    var shouldDoBackup = false
    
    //MARK: private helpers
    private var cancelWriting = false
    
    private lazy var writerQueue: dispatch_queue_t = {
        return dispatch_queue_create("writer", DISPATCH_QUEUE_SERIAL)
    }()
    
    //MARK: processing
    
    func write(fileContents: Array<FileContent>, progressHandler: (NSURL) -> Void, completionHandler: (Bool, Array<(NSURL)>, NSError!) -> Void) {
        dispatch_async(self.writerQueue) {
            var writtenFiles = Array<(NSURL)>()
            
            let result = self.write(fileContents, writtenFiles:&writtenFiles, progressHandler: progressHandler)
        
            //report success | callback on main thread
            let br = result.0
            var error = result.1
            if(error == nil) {
                error = NSError(domain: "CopyRightWriter", code: 0, userInfo: [NSLocalizedDescriptionKey:"unkown error"])
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(br, writtenFiles, self.cancelWriting ? nil : error)
            }
        }
    }
    
    func cancelAllProcessing(completionHandler: () -> Void) {
        cancelWriting = true
        dispatch_async(self.writerQueue, { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.cancelWriting = false
                completionHandler()
            })
        })
    }
    //MARK: -
    
    private func write(fileContents: Array<FileContent>, inout writtenFiles: Array<(NSURL)>, progressHandler: (NSURL) -> Void) -> (Bool, NSError?) {
        for content in fileContents {
            if(self.cancelWriting) {
                return (false, nil)
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                progressHandler(content.url)
            })
            
            //write it
            do {
                try content.content.writeToURL(content.url, atomically: false, encoding: NSUTF8StringEncoding)
            }
            catch let e as NSError {
                return (false, NSError(domain: "CopyRightWriter", code: 21, userInfo: [NSLocalizedDescriptionKey:"error writing file content to disk for \(content.url): \(e)"]))
            }
            
            writtenFiles.append(content.url)
        }
        
        return (true, nil)
    }
}
