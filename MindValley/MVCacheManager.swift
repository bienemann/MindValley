//
//  MVCacheManager.swift
//  MindValley
//
//  Created by Allan Denis Martins on 28/11/16.
//  Copyright © 2016 bienemann. All rights reserved.
//

import UIKit
import Foundation

class MVCacheManager: NSObject {

    private var cache = Cache<String, CachedObject>()
    
    public static let shared = MVCacheManager()
    public var config : CacheConfig {
        get{
            return self.cache.config
        }
        set (newValue){
            self.cache.config = newValue
        }
    }
    
    public func contains(address: String) -> Bool{
        return self.cache[address] != nil
    }
    
    public func data(atURL: URL) -> Data?{
        guard let d = self.cache[atURL.absoluteString] else {
            return nil
        }
        return d.data
    }
    
    public func insert(data: Data, url: URL){
        let obj = CachedObject(data, timerFrequency: self.cache.config.relevanceDropTime, lifeTime: 0.0)
        self.cache[url.absoluteString] = obj
    }
}

internal struct CachedObject {
    
    public var data : Data = Data()
    public var invalidateAfter: TimeInterval = 0.0 //(never)
    public var relevance : UInt = 0
    
    public init(_ data: Data, timerFrequency: TimeInterval, lifeTime: TimeInterval) {
        self.invalidateAfter = lifeTime
        let timer = Timer(timeInterval: timerFrequency, target: self, selector: Selector(("dropRelevance:")), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    private mutating func dropRelevance(timer: Timer){
        self.relevance -= 1
    }
    
}

internal struct CacheConfig {
    
    var cacheSize : Int = 1024*1024*4 //default 4mb
    var relevanceDropTime : TimeInterval = 0.0

}

internal struct Cache<Key : Hashable, Value> {
    
    fileprivate var contents : [Key: Value] = [:]
    
    fileprivate var config = CacheConfig()
    
    public mutating func insert(path: Key, data: Value){
        guard let _ = contents[path] else {
            contents.updateValue(data, forKey: path)
            return;
        }
    }
    
    private func insertNewObject (key: String, value: CachedObject){
        
        //check if exists
        //yes:
        //  increment call count
        //no:
        //  check if smaller than cache size
        //  yes:
        //      check if smaller than available space
        //      yes:
        //          insert object
        //          return true
        //      no:
        //          check if can delete objects until it fits
        //          yes:
        //              delete objects
        //              insert object
        //              return true
        //          no:
        //              return false
        //  no:
        //      return false
        
    }

}

extension Cache : Collection, ExpressibleByDictionaryLiteral {
    typealias Key = String
    typealias Value = CachedObject
    typealias Iterator = DictionaryIterator<Key, Value>
    typealias Index = DictionaryIndex<Key, Value>
    
    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == (key: Key, value: Value) {
        for (k, v) in sequence {
            insert(path: k, data: v)
        }
    }
    
    init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(elements.map { (key: $0.0, value: $0.1) })
    }
    
    func makeIterator() -> Iterator {
        return contents.makeIterator()
    }
    
    var startIndex: Index {
        return contents.startIndex
    }
    
    var endIndex: Index {
        return contents.endIndex
    }
    
    func index(after i: Index) -> Index {
        return contents.index(after: i)
    }
    
    subscript (key : String) -> Value? {
        get {
            return contents[key]
        }
        set (newValue) {
            insert(path: key, data: newValue!)
        }
    }
    
    subscript (position: Index) -> Iterator.Element {
        return contents[position];
    }
    
}
