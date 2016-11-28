//
//  MVCacheManager.swift
//  MindValley
//
//  Created by resource on 11/28/16.
//  Copyright © 2016 bienemann. All rights reserved.
//

import XCTest

class MVCacheManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        
        
        super.tearDown()
    }

    func testInsert() {
        MVCacheManager.shared.insert(data: Data(), url: URL(string:"http://testURL.com")!)
        XCTAssertTrue(MVCacheManager.shared.contains(address:"http://testURL.com"))
    }
    
    func testCacheOverflow(){
        MVCacheManager.shared.insert(data: Data(count: 1024*1024*6), url: URL(string:"http://testLarge.com")!)
        XCTAssertFalse(MVCacheManager.shared.contains(address:"http://testLarge.com"),
                       "gravou objecto maior que o cache")
    }
    
    func testMakeSpace(){
        MVCacheManager.shared.config.cacheSize = 1024*1024*2
        MVCacheManager.shared.insert(data: Data(count: (1024*1024)/2),
                                     url: URL(string:"http://file1.com")!)
        MVCacheManager.shared.insert(data: Data(count: (1024*1024)/2),
                                     url: URL(string:"http://file2.com")!)
        MVCacheManager.shared.insert(data: Data(count: (1024*1024)/2),
                                     url: URL(string:"http://file3.com")!)
        MVCacheManager.shared.insert(data: Data(count: (1024*1024)),
                                     url: URL(string:"http://file4.com")!)
        XCTAssertFalse(MVCacheManager.shared.contains(address:"http://file1.com"))
        XCTAssertTrue(MVCacheManager.shared.contains(address:"http://file2.com"))
        XCTAssertTrue(MVCacheManager.shared.contains(address:"http://file4.com"))
    }
    
}
