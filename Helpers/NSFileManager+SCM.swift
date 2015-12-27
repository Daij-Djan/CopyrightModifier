//
//  NSFileManager+fileInfo.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 07/09/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Foundation
import ObjectiveGit

extension NSFileManager {
    var scmLog:Bool { get { return false } }

    // MARK: SCM state

    func SCMStateOfFileAtURL(fileUrl:NSURL) ->FileInfoOptions {
        //check git
        if self.gitStateOfFileAtURL(fileUrl) {
            return FileInfoOptions.GIT.union(.LOCAL)
        }

        return FileInfoOptions.LOCAL
    }
    
    func gitStateOfFileAtURL(fileUrl:NSURL) -> Bool {
        let repo: GTRepository? = GTRepository.findCachedRepositoryWithURL(fileUrl)
        return repo != nil
    }

    // MARK: date
    
    func creationDateOfFileAtURL(fileUrl:NSURL, options:FileInfoOptions) -> NSDate! {
        var date:NSDate?
        
        //get first git date
        if options.contains(.GIT) {
            date = self.gitCreationDateOfFileAtURL(fileUrl)
        }
        
        //fallback to local creation date
        if date == nil {
            if options.contains(.LOCAL) {
                date = self.localCreationDateOfFileAtURL(fileUrl)
            }
        }
        
        return date
    }

    private func gitCreationDateOfFileAtURL(fileUrl:NSURL) -> NSDate? {
        if let repo = GTRepository.findCachedRepositoryWithURL(fileUrl) {
            if let repoPath = repo.fileURL.path {
                if var relativePath = fileUrl.path?.stringByReplacingOccurrencesOfString(repoPath, withString: "") {
                    if(relativePath.hasPrefix("/")) {
                        relativePath = relativePath.substringFromIndex(relativePath.startIndex.advancedBy(1))
                    }
                    if let commitAndPath = repo.findCachedFileHistory(relativePath)?.last {
                        return commitAndPath.0.commitDate
                    }
                }
            }
        }
        return nil
    }
    
    private func localCreationDateOfFileAtURL(fileUrl:NSURL) -> NSDate? {
        //get file date
        var creationDate: AnyObject?
        do {
            try fileUrl.getResourceValue(&creationDate, forKey:NSURLCreationDateKey)
        }
        catch {
            creationDate = nil
        }

        if self.scmLog {
            print("local date = \(creationDate)")
        }
        
        return creationDate as? NSDate
    }
    
    // MARK: author

    func authorOfFileAtURL(fileUrl:NSURL, options:FileInfoOptions, matchToOSX:Bool) -> String {
        var author:NSString = ""
        
        //get git author
        if options.contains(.GIT) {
            if let gitAuthor = self.gitAuthorOfFileAtURL(fileUrl) {
                author = gitAuthor
            }
        }
        
        //fallback to native
        if author.length == 0 {
            if options.contains(.LOCAL) {
                author = self.localAuthorOfFileAtURL(fileUrl)
            }
        }
    
        //try if we can match it
        if matchToOSX {
            if author.length > 0 {
                let longUserName = NSFullUserName()
                let shortUserName = NSUserName()
            
                if(author.isEqualToString(shortUserName)) {
                    author = longUserName
                }
            }
        }
        
        return author as String
    }

    private func gitAuthorOfFileAtURL(fileUrl:NSURL) -> String? {
        if let repo = GTRepository.findCachedRepositoryWithURL(fileUrl) {
            if let repoPath = repo.fileURL.path {
                if var relativePath = fileUrl.path?.stringByReplacingOccurrencesOfString(repoPath, withString: "") {
                    if(relativePath.hasPrefix("/")) {
                        relativePath = relativePath.substringFromIndex(relativePath.startIndex.advancedBy(1))
                    }
                    if let commitAndPath = repo.findCachedFileHistory(relativePath)?.last {
                        if let sig = commitAndPath.0.author {
                            //sapient hack
                            if let name = sig.name where sig.email?.hasSuffix("@sapient.com") == true {
                                let set = NSCharacterSet.decimalDigitCharacterSet()
                                return name.stringByTrimmingCharactersInSet(set)
                            }
                            return sig.name != nil ? sig.name : sig.email
                        }
                    }
                }
            }
        }
        return nil
    }

    private func localAuthorOfFileAtURL(fileUrl:NSURL) -> String {
        let username: NSString
        
        //native
        let longUserName = NSFullUserName()
        let shortUserName = NSUserName()
        
        //fallback to native
        if(longUserName.characters.count > 0) {
            username = longUserName
        }
        else {
            username = shortUserName
        }
        
        if self.scmLog && username.length > 0 {
            print("native username = \(username)")
        }
    
        return username as String
    }
}