//
//  GTRepository+FindFirstCommit.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 11/22/15.
//  Copyright © 2015 Dominik Pich. All rights reserved.
//

import Foundation
import ObjectiveGit

var GTRepository_cachedHistories = Dictionary<String, [(GTCommit,String)]>()

extension GTRepository {
    //searches for a file's history
    
    func findCachedFileHistory(_ relativeFilePath:String) -> [(GTCommit,String)]? {
        var history:[(GTCommit,String)]?
        
        //search in our list of cached repos
        if GTRepository_cachedHistories.count > 0 {
            history = GTRepository_cachedHistories[relativeFilePath]
        }
        
        if  history != nil {
            return history
        }
        
        //search on disk
        history = findFileHistory(relativeFilePath)
        
        if(history != nil) {
            GTRepository_cachedHistories[relativeFilePath] = history
        }
        
        return history
    }

    func findFileHistory(_ relativeFilePath:String) -> [(GTCommit,String)]? {
        var seen = [(GTCommit,String)]()

        //setup enumerator
        var enumerator: GTEnumerator!
        do {
            enumerator = try GTEnumerator(repository: self)
            enumerator.reset( options: GTEnumeratorOptions.topologicalSort.union(.timeSort))
            let head = try self.headReference()
            try enumerator.pushSHA(head.oid.sha)
        }
        catch let error as NSError {
            print("cant setup enumerator: \(error)")
            return nil
        }

        //get HEAD commit
        var commit = enumerator.nextObject() as! GTCommit?

        //look for commits
        var seenInCommit: GTCommit?
        var filePath = relativeFilePath
        var breakLoop = false
//        var i = 1
        while(commit != nil) {
//            print(i++)
            
            autoreleasepool {
                //check tree and see if touches file
                do {
                    //throws error if not seen!
                    try commit!.tree?.entry(withPath: filePath)
                    assert(commit != nil)
                    
                    seenInCommit = commit
                    seen.append((commit!, filePath))
                    
                }
                catch {
                    var refound = false
                    
                    //might have been renamed?! see if we can find it via it's sha
                    if let tree = commit?.tree, let oldTree = seenInCommit?.tree {
                        do {
                            let entry = try oldTree.entry(withPath: filePath)
                            if entry.type == .blob {
                                if let sha = try entry.gtObject().sha {
                                    if let itemAndPath = tree.entryWithBlobSHA(sha) {
                                        filePath = itemAndPath.1
                                        refound = true
                                        
                                        assert(commit != nil)
                                        seenInCommit = commit
                                        seen.append((commit!, filePath))
                                    }
                                }
                            }
                        }
                        catch {
                            print("cant get file blob SHA")
                        }
                    }
                    
                    if !refound {
                        breakLoop = true;
                    }
                }
            }
            if breakLoop {
                break;
            }
            commit = enumerator.nextObject() as! GTCommit?
        }
        
        //now we filter the commits. starting with the last :)
        var changed = [(GTCommit,String)]()
        var oldSha: String?
        var oldPath: String?
        
        autoreleasepool {
            for entry in seen.reversed() {
                var sha: String?
                let path = entry.1
                
                //get seen sha AND path
                do {
                    if let tree = entry.0.tree {
                        let entry = try tree.entry(withPath: path)
                        if entry.type == .blob {
                            sha = try entry.gtObject().sha
                        }
                    }
                }
                catch {
                    print("cant get file blob SHA")
                }
                
                //only add when sha or path chaanged
                if(oldSha == nil) {
                    changed.append(entry)
                }
                else if(oldSha != sha) {
                    changed.append(entry)
                }
                else {
                    //fallback to path!
                    if(oldPath == nil) {
                        changed.append(entry)
                    }
                    else if(oldPath != path) {
                        changed.append(entry)
                    }
                }
                oldSha = sha
                oldPath = path
            }
            
            changed = changed.reversed()
        }
        return changed
    }
}
