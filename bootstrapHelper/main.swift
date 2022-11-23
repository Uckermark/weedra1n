//
//  bootstrapHelper.swift
//  bootstrapHelper
//
//  Created by Leonard Lausen on 22.11.22.
//

import ArgumentParser
import Foundation

struct Cache: ParsableCommand {
    
    @Option(name: .shortAndLong, help: "bootstrap url")
    var url: String
    
    @Flag(name: .shortAndLong, help: "download bootstrap")
    var load = false
    
    mutating func run() throws {
        guard getuid() == 0 else { fatalError()}
        
        if load {
            NSlog("Downloading bootstrap")
            FileDownloader.loadFileSync(url:URL(string: url)) { (path, error) in
                NSlog("Downloaded bootstrap to \(path)")
            }
        }
    }
}

class FileDownloader {
    static func loadFileSync(url: URL, completion: @escaping (String?, Error?) -> Void)
    {
        let documentsUrl = URL(string: "file:///var/mobile/Documents/weedra1n/")!
        
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            print("File already exists [\(destinationUrl.path)]")
            completion(destinationUrl.path, nil)
        }
        else if let dataFromURL = NSData(contentsOf: url)
        {
            if dataFromURL.write(to: destinationUrl, atomically: true)
            {
                print("file saved [\(destinationUrl.path)]")
                completion(destinationUrl.path, nil)
            }
            else
            {
                print("error saving file")
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(destinationUrl.path, error)
            }
        }
        else
        {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(destinationUrl.path, error)
        }
    }
}

Cache.main()
