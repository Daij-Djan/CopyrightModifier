//
//  GTTreeEntry+EntryWithSHA.swift
//  GitLogView
//
//  Created by Dominik Pich on 11/24/15.
//  Copyright © 2015 Dominik Pich. All rights reserved.
//

import Foundation
import ObjectiveGit

extension GTTree {
    
    /// Get an entry by it's BLOBs sha
    ///
    /// SHA - the SHA of the entry's blob
    ///
    /// returns a GTTreeEntry and its relative path or nil if there is nothing with the specified Blob SHA
    public func entryWithBlobSHA(_ SHA: String) -> (GTTreeEntry, String)? {
        var item : GTTreeEntry?
        var path : String?
        
        do {
            try self.enumerateEntries(with: GTTreeEnumerationOptions.post, block: { (entry, relativePath, stopPointer) -> Bool in
                guard entry.type == .blob else {
                    return false;
                }
                
                var br = false
                autoreleasepool {
                    let entryPath = relativePath + entry.name
                    
                    do {
                        let obj = try entry.gtObject()
                        let sha2 = obj.sha
                        
                        if SHA == sha2 {
                            item = entry
                            path = entryPath
                            stopPointer.pointee = true
                            br =  true
                        }
                    }
                    catch {
                    }
                }
                return br
            })
        }
        catch {
        }
        
        if item != nil && path != nil {
            return (item!, path!)
        }
        return nil
    }

}
