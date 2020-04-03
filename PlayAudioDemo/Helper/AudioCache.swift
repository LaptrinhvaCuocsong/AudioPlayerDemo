//
//  AudioCache.swift
//  PlayAudioDemo
//
//  Created by Apple on 4/1/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Cache
import Foundation

let kAudioCache = AudioCache.shared

class AudioCache {
    static let shared = AudioCache()

    // MARK: - Private properties

    private let storage: Storage<Data>?

    private let diskConfig = DiskConfig(
        name: "DiskCacheAudio",
        expiry: .date(Date().addingTimeInterval(2 * 3600)),
        maxSize: 100 * 1024 * 1024,
        directory: try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                appropriateFor: nil, create: true).appendingPathComponent("CacheAudio"),
        protectionType: .complete
    )

    private let memoryConfig = MemoryConfig(
        expiry: .date(Date().addingTimeInterval(2 * 60)),
        countLimit: 50,
        totalCostLimit: 50
    )

    private init() {
        storage = try? Storage<Data>(diskConfig: diskConfig,
                                     memoryConfig: memoryConfig,
                                     transformer: TransformerFactory.forData())
    }

    // MARK: - Public method

    subscript(key: String) -> Data? {
        get {
            return getData(key: key)
        } set {
            if getData(key: key) != nil {
                try? storage?.removeObject(forKey: key)
            }
            if let data = newValue {
                try? storage?.setObject(data, forKey: key)
            }
        }
    }

    func set(data: Data, for key: String) {
        do {
            try storage?.setObject(data, forKey: key)
        } catch {
            print("Cache audio fail with key: \(key)")
        }
    }

    func getData(key: String) -> Data? {
        return try? storage?.object(forKey: key)
    }
}
