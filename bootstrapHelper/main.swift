//
//  bootstrapHelper.swift
//  bootstrapHelper
//
//  Created by Leonard Lausen on 22.11.22.
//

import Foundation
import ArgumentParser

struct Cache: ParsableCommand {
    
    @Flag(name: .shortAndLong, help: "download bootstrap")
    var load = false
    
    mutating func run() throws {
        guard getuid() == 0 else { fatalError()}
        
        if load {
            let url = URL(string: "https://nightly.link/Uckermark/weedra1n/workflows/devbuild/helper/bootstrap.zip")!
            NSLog("Downloading bootstrap")
            loadFileSync(url: url) { (path, error) in
                NSLog("Downloaded bootstrap to \(path)")
            }
            unzip(file: "bootstrap.zip")
        }
    }
}

Cache.main()
