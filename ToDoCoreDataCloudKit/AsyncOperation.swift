//
//  AsyncOperation.swift
//  ToDoCoreDataCloudKit
//
//  Created by Wismin Effendi on 9/29/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import Foundation

class AsyncOperation: Operation {
    
    enum State: String {
        case Ready, Executing, Finished
        
        fileprivate var keyPath: String {
            return "is" + rawValue
        }
    }
    
    var state = State.Ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
}

//MARK: - Operation Overrides
extension AsyncOperation {
    override var isReady: Bool {
        return super.isReady && state == .Ready
    }
    
    override var isExecuting: Bool {
        return state == .Executing
    }
    
    override var isFinished: Bool {
        return state == .Finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        if isCancelled {
            state = .Finished
            return
        }
        main()
        state = .Executing
    }
    
    override func cancel() {
        state = .Finished
    }
}
