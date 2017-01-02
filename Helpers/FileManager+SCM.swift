//
//  NSFileManager+fileInfo.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 07/09/14.
//  Copyright (c) 2014 Dominik Pich. All rights reserved.
//

import Foundation
import ObjectiveGit

extension FileManager {
    var scmLog:Bool { get { return false } }

    // MARK: SCM state

    func SCMStateOfFileAtURL(_ fileUrl:URL) ->FileInfoOptions {
        //check git
        if self.gitStateOfFileAtURL(fileUrl) {
            return FileInfoOptions.GIT.union(.LOCAL)
        }

        return FileInfoOptions.LOCAL
    }
    
    func gitStateOfFileAtURL(_ fileUrl:URL) -> Bool {
        let repo: GTRepository? = GTRepository.findCachedRepositoryWithURL(fileUrl)
        return repo != nil
    }

    // MARK: date
    
    func creationDateOfFileAtURL(_ fileUrl:URL, options:FileInfoOptions) -> Date! {
        var date:Date?
        
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

    fileprivate func gitCreationDateOfFileAtURL(_ fileUrl:URL) -> Date? {
        if let repo = GTRepository.findCachedRepositoryWithURL(fileUrl) {
            let repoPath = repo.fileURL.path
            var relativePath = fileUrl.path.replacingOccurrences(of: repoPath, with: "")
            if relativePath.characters.count > 1 {
                if(relativePath.hasPrefix("/")) {
                    relativePath = relativePath.substring(from: relativePath.characters.index(relativePath.startIndex, offsetBy: 1))
                }
            }
            if let commitAndPath = repo.findCachedFileHistory(relativePath)?.last {
                return commitAndPath.0.commitDate
            }
        }
        return nil
    }
    
    fileprivate func localCreationDateOfFileAtURL(_ fileUrl:URL) -> Date? {
        //get file date
        var creationDate: AnyObject?
        do {
            try (fileUrl as NSURL).getResourceValue(&creationDate, forKey:URLResourceKey.creationDateKey)
        }
        catch {
            creationDate = nil
        }

        if self.scmLog {
            print("local date = \(creationDate)")
        }
        
        return creationDate as? Date
    }
    
    // MARK: author

    func authorOfFileAtURL(_ fileUrl:URL, options:FileInfoOptions, matchToOSX:Bool = true) -> String {
        var author:NSString = ""
        
        //get git author
        if options.contains(.GIT) {
            if let gitAuthor = self.gitAuthorOfFileAtURL(fileUrl) {
                author = gitAuthor as NSString
            }
        }
        
        //fallback to native
        if author.length == 0 {
            if options.contains(.LOCAL) {
                author = self.localAuthorOfFileAtURL(fileUrl) as NSString
            }
        }
    
        //try if we can match it
        if matchToOSX {
            if author.length > 0 {
                let longUserName = NSFullUserName()
                let shortUserName = NSUserName()
            
                if(author.isEqual(to: shortUserName)) {
                    author = longUserName as NSString
                }
            }
        }
        
        return author as String
    }

    fileprivate func gitAuthorOfFileAtURL(_ fileUrl:URL) -> String? {
        if let repo = GTRepository.findCachedRepositoryWithURL(fileUrl) {
            let repoPath = repo.fileURL.path
            var relativePath = fileUrl.path.replacingOccurrences(of: repoPath, with: "")
            if relativePath.characters.count > 1 {
                if(relativePath.hasPrefix("/")) {
                    relativePath = relativePath.substring(from: relativePath.characters.index(relativePath.startIndex, offsetBy: 1))
                }
            }
            if let commitAndPath = repo.findCachedFileHistory(relativePath)?.last {
                if let sig = commitAndPath.0.author {
                    //sapient hack
                    if let name = sig.name, sig.email?.hasSuffix("@sapient.com") == true {
                        let set = CharacterSet.decimalDigits
                        return name.trimmingCharacters(in: set)
                    }
                    return sig.name != nil ? sig.name : sig.email
                }
            }
        }
        return nil
    }

    fileprivate func localAuthorOfFileAtURL(_ fileUrl:URL) -> String {
        let username: NSString
        
        //native
        let longUserName = NSFullUserName()
        let shortUserName = NSUserName()
        
        //fallback to native
        if(longUserName.characters.count > 0) {
            username = longUserName as NSString
        }
        else {
            username = shortUserName as NSString
        }
        
        if self.scmLog && username.length > 0 {
            print("native username = \(username)")
        }
    
        return username as String
    }
}
