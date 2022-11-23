//
//  FileDownloader.swift
//  weedra1n
//
//  Created by Uckermark on 23.11.22.
//

import Foundation


func loadFileSync(url: URL, completion: @escaping (String?, Error?) -> Void)
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
