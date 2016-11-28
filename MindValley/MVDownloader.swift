//
//  AsyncDownloader.swift
//  MindValley
//
//  Created by resource on 11/25/16.
//  Copyright © 2016 bienemann. All rights reserved.
//

import Foundation

class MVDownloader : NSObject {
    
    static let shared = MVDownloader()
    
    let dlQueue = DispatchQueue(label: "com.mindvalley.downloader", qos: .background)
    let dispatchGroup = DispatchGroup()
    
    var taskQueue = Array<DispatchWorkItem>()
    var runningTasks = Array<DispatchWorkItem>()
    var maxConcurrentDownloads = 10
    
    override init(){
        super.init()
    }
    
    func download(url: URL, cache: Bool = true, invalidateAfter: Int = 60*3,
                  completion: @escaping (Data?, URLResponse?) -> Void,
                  error: @escaping (Error?) -> Void) -> Void {
        
        dispatchGroup.enter()
        
        
        if (MVCacheManager.shared.contains(address:url.absoluteString)) {
            completion(MVCacheManager.shared.data(atURL: url), nil)
            return;
        }
        
        let session = URLSession.shared
        let request = URLRequest(url: URL(string: "http://google.com")!)
        let task = session.dataTask(with: request) { (data, response, error) in
            if (error != nil){
                //TODO: handle error
                return;
            }
            
            guard let _ = response else {
                print("holy shit there's no response and no error????")
                return;
            }
            
            guard let _ = data else {
                print("\(response!)")
                return;
            }
            
            MVCacheManager.shared.insert(data: data!, url: url)
            
            print("\(response!)")
            print("\(data!)")
            
            
        }
        
        dlQueue.async {
            task.resume()
        }
        
    }
    
}
