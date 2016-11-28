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
        d.relevance += 1
        return d.data
    }
    
    public func insert(data: Data, url: URL){
        let obj = CachedObject(data, timerFrequency: self.cache.config.relevanceDropTime, lifeTime: 0.0)
        self.cache[url.absoluteString] = obj
    }
}

@objc class CachedObject : NSObject {
    
    public var data : Data = Data()
    public var invalidateAfter: TimeInterval = 0.0 //(never)
    public var relevance : UInt = 0
    public var timer = Timer()
    
    public init(_ data: Data, timerFrequency: TimeInterval, lifeTime: TimeInterval) {
        super.init()
        self.data = data
        self.invalidateAfter = lifeTime
        self.timer = Timer(timeInterval: timerFrequency,
                           target: self, 
                           selector: #selector(self.dropRelevance(_:)),
                           userInfo: nil, repeats: true)
        self.timer.fire()
    }
    
    @objc func dropRelevance(_ timer: Timer){
        if self.relevance > 0 {
            self.relevance -= 1
        }
    }
    
}

internal struct CacheConfig {
    
    var cacheSize : Int = 1024*1024*4 //default 4mb
    var relevanceDropTime : TimeInterval = 0.0
    var relevanceThreshold : UInt = 4

}

internal struct Cache<Key : Hashable, Value> {
    
    fileprivate var contents : [Key: Value] = [:]
    fileprivate var orderedKeys : [Key] = []
    
    fileprivate var config = CacheConfig()
    
    public mutating func insert (_ value: Value, forAddress: Key){
        
        if contents[forAddress] != nil {
            return //data is cached
        }
        
        if value.data.count > config.cacheSize {
            return //data larger than cache size
        }
        
        if  value.data.count > availableSpace {
            return //not enough space
        }else if value.data.count > freeSpace {
            self.makeSpace(size: value.data.count)
        }
        
        contents[forAddress] = value
        orderedKeys.append(forAddress)
    }
    
    public mutating func remove(key:Key){
        guard let _ = contents[key] else {
            return
        }
        contents[key]!.timer.invalidate()
        contents.removeValue(forKey: key)
        orderedKeys.remove(at: orderedKeys.index(of: key)! )
    }
    
    public var freeSpace : Int {
        get {
            var usedSpace = 0
            for object in contents.values {
                usedSpace += object.data.count
            }
            return config.cacheSize - usedSpace
        }
    }
    
    public var availableSpace : Int {
        get {
            var space = config.cacheSize
            for object in contents.values {
                if object.relevance >= config.relevanceThreshold {
                    space -= object.data.count
                }
            }
            return space
        }
    }
    
    public mutating func makeSpace(size: Int) {
        
        var freedSpace = freeSpace
        var iterator = 0
        
        var toRemove = [Value]()
        
        while freedSpace < size {
            if iterator < self.count {
                if self[iterator]!.relevance < config.relevanceThreshold {
                    freedSpace += self[iterator]!.data.count
                    toRemove.append(self[iterator]!)
                }
                iterator += 1
            }else { continue }
        }
        
        for value in toRemove {
            for key in self.allKeys(forValue: value) {
                self[key] = nil
            }
        }
        
    }
}

extension Cache : Collection, ExpressibleByDictionaryLiteral {
    typealias Key = String
    typealias Value = CachedObject
    typealias Iterator = DictionaryIterator<Key, Value>
    typealias Index = DictionaryIndex<Key, Value>
    
    init<S: Sequence>(_ sequence: S) where S.Iterator.Element == (key: Key, value: Value) {
        for (k, v) in sequence {
            insert(v, forAddress: k)
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
    
    func allKeys(forValue val: Value) -> [Key] {
        return self.filter { $1 == val }.map { $0.0 }
    }
    
    subscript (key : String) -> Value? {
        get {
            return contents[key]
        }
        set (newValue) {
            if newValue == nil {
                self.remove(key:key)
            }else{
                self.insert(newValue!, forAddress: key)
            }
        }
    }
    
    subscript (position: Index) -> Iterator.Element {
        return contents[position]
    }
    
    subscript(index: Int) -> Value? {
        get {
            precondition(index < orderedKeys.count, "out of bounds")
            let k = orderedKeys[index]
            return contents[k]!
        }
        set (newValue) {
            if newValue == nil {
                self.remove(key: orderedKeys[index])
            }
        }
    }
    
}
