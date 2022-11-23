//
//  unzipper.swift
//  weedra1n
//
//  Created by Uckermark on 23.11.22.
//

import Foundation
import SWCompression

func unzip(file: String) {
    let documentsUrl = URL(string: "file:///var/mobile/Documents/weedra1n")!
    let zipUrl = documentsUrl.appendingPathComponent(file)
    do {
        let data = try Data(contentsOf: zipUrl)
        let container = try ZipContainer.open(container: data)
        for entry in container {
            var path = entry.info.name
            if path.first == "." {
                path.removeFirst()
            }
            NSLog("Unpacking \(path)")
            guard let data = entry.data else {
                DispatchQueue.main.async {
                    NSLog("Invalid Item in zip")
                }
                return
            }
            let entryUrl = documentsUrl.appendingPathComponent(path)
            try data.write(to: entryUrl)
        }
        try FileManager().removeItem(at: zipUrl)
    } catch {
        DispatchQueue.main.async {
            NSLog("Error while unpacking: \(error.localizedDescription)")
        }
    }
}
