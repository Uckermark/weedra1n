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
            NSLog("Downloading bootstrap")
            FileDownloader.loadFileSync(url:URL(string: url)!) { (path, error) in
                NSLog("Downloaded bootstrap to \(path)")
            }
        }
    }
}

Cache.main()
