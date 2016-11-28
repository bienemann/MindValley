//
//  ViewController.swift
//  MindValley
//
//  Created by resource on 11/25/16.
//  Copyright © 2016 bienemann. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        MVCacheManager.shared.config.relevanceDropTime = TimeInterval(floatLiteral: 80)
        MVDownloader.shared.download(url: URL(string:"http://google.com")!, cache: true,  invalidateAfter: 0, completion: { (data, response) in
            
        }, error:{ (error) in
            
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

