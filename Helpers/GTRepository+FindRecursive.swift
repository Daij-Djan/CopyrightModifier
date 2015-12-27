//
//  GTRepository+Find.swift
//  CoprightModifier
//
//  Created by Dominik Pich on 15/06/15.
//  Copyright (c) 2015 Dominik Pich. All rights reserved.
//

import Foundation
import ObjectiveGit

var GTRepository_cachedRepositories = Dictionary<String, GTRepository>()

extension GTRepository {
    //searches for the closest repo for a given fileUrl. Same as the git CLI client.
    
    class func findCachedRepositoryWithURL(fileUrl:NSURL) -> GTRepository? {
        
        //search on disk
        var path = fileUrl.path

        var repo:GTRepository?
        
        //search in our list of cached repos
        if GTRepository_cachedRepositories.count > 0 {
            while(repo == nil && path != nil) {
                repo = GTRepository_cachedRepositories[path!]
                
                //change stringByDeletingLastPathComponent behaviour ;)
                if path == "/" {
                    path = nil
                }
                else {
                    let url = NSURL(fileURLWithPath: path!)
                    path = url.URLByDeletingLastPathComponent?.path
                }
            }
        }
        
        if  repo != nil {
            return repo
        }

        if  path == nil {
            return nil
        }

        //search on disk
        repo = findRepositoryWithURL(NSURL(fileURLWithPath: path!))
        
        if(repo != nil) {
            GTRepository_cachedRepositories[path!] = repo
        }

        return repo
    }

    class func findRepositoryWithURL(fileUrl:NSURL) -> GTRepository? {
        //search on disk
        var path = fileUrl.path
        var repo:GTRepository?

        //search on disk
        path = fileUrl.path
        
        while(repo == nil && path != nil) {
            let url = NSURL(fileURLWithPath: path!)
            do {
                try repo = GTRepository(URL: url)
                if repo != nil {
                    return repo;
                }
            }
            catch {
            }
            
            //change stringByDeletingLastPathComponent behaviour ;)
            if path == "/" {
                path = nil
            }
            else {
                let url = NSURL(fileURLWithPath: path!)
                path = url.URLByDeletingLastPathComponent?.path
            }
        }
        
        
        return repo
    }
}