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
    fileprivate var cancelWriting = false
    
    fileprivate lazy var writerQueue: DispatchQueue = {
        return DispatchQueue(label: "writer", attributes: [])
    }()
    
    //MARK: processing
    
    func write(_ fileContents: Array<FileContent>, progressHandler: @escaping (URL) -> Void, completionHandler: @escaping (Bool, Array<(URL)>, NSError?) -> Void) {
        self.writerQueue.async {
            var writtenFiles = Array<(URL)>()
            
            let result = self.write(fileContents, writtenFiles:&writtenFiles, progressHandler: progressHandler)
        
            //report success | callback on main thread
            let br = result.0
            var error = result.1
            if(error == nil) {
                error = NSError(domain: "CopyRightWriter", code: 0, userInfo: [NSLocalizedDescriptionKey:"unkown error"])
            }
            
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
