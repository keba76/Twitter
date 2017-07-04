//
//  CoreOperationAsync.swift
//  TwitterTest
//
//  Created by Ievgen Keba on 6/16/17.
//  Copyright © 2017 Harman Inc. All rights reserved.
//

import Foundation

class CoreOperationAsync: Operation {
    
    override init() {
        super.init()
        self._ready = true
    }
    
    override var isAsynchronous: Bool { return true }
    
    private var _executing = false {
        willSet {
            willChangeValue(forKey: "isExecuting")
        }
        didSet {
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool { return _executing }
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool { return _finished }
    
    private var _ready = false {
        willSet {
            willChangeValue(forKey: "isReady")
        }
        didSet {
            didChangeValue(forKey: "isReady")
        }
    }
    
    override var isReady: Bool { return _ready }
    
    override func start() {
        if isCancelled {
            _ready = false
            _executing = false
            _finished = true
        } else if !isExecuting {
            _ready = false
            _executing = true
            _finished = false
        }
    }
    
    func finish() {
        if isExecuting { _executing = false }
        _finished = true
    }
}
