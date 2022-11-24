//
//  main.swift
//  PogoHelper
//
//  Created by Amy While on 12/09/2022.
//

import Foundation
import ArgumentParser

struct Strap: ParsableCommand {
    
    @Flag(name: .shortAndLong, help: "Download latest build")
    var update: Bool = false
    
    @Flag(name: .shortAndLong, help: "Extract ipa from zip")
    var extract: Bool = false
    
    @Flag(name: .shortAndLong, help: "Remove the custom documents directory")
    var clean: Bool = false
    
    @Flag(name: .long, help: "Download latest build from dev branch")
    var dev: Bool = false
    
    mutating func run() throws {
        NSLog("[weedInstaller] Spawned!")
        guard getuid() == 0 else { fatalError() }

         if update {
            if !FileManager().fileExists(atPath: "/var/mobile/Documents/weedra1n/") {
                let path = URL(string: "file:///var/mobile/Documents/weedra1n")!
                do {
                    try FileManager().createDirectory(at: path, withIntermediateDirectories: false)
                } catch {
                    NSLog("Could not create working directory: \(error.localizedDescription)")
                }
            }
            let url: URL
            if dev {
                url = URL(string: "https://nightly.link/Uckermark/weedra1n/workflows/devbuild/dev/weedra1n.zip")!
            } else {
                url = URL(string:
"https://nightly.link/Uckermark/weedra1n/workflows/build/main/weedra1n.zip")!
            }
            loadFileSync(url: url) { (path, error) in
                NSLog("Downloaded to path \(path!)")
            }
        } else if extract {
            unzip(file: "weedra1n.zip")
        } else if clean {
            let docPath = "/var/mobile/Documents/weedra1n/"
            let updateFiles = ["\(docPath)weedra1n.ipa", "\(docPath)weedra1n.zip"]
            for file in updateFiles {
                try? FileManager().removeItem(atPath: file)
            }
        }
    }
}

Strap.main()
