//
//  DownloadManager.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import Alamofire
import RxSwift

enum ChunkedData<T> {
    case progress(x: Double)
    case data(x: T)
}

protocol DownloadToken {
    func pause()
    func resume()
    func cancel()
}

extension DownloadRequest: DownloadToken {
    func pause() {
        suspend()
    }
}

struct DownloadManager {
    
    static let `default`: DownloadManager = DownloadManager()
    
    let sessionManager = { () -> SessionManager in
    
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 3
    
        return SessionManager(configuration: config)
    }()
    
    func download(x: URLConvertible) -> (Observable<ChunkedData<URL>>, DownloadToken) {
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(try! x.asURL().absoluteString)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let task = sessionManager.download(x, to: destination)
        
        let o: Observable<ChunkedData<URL>> = Observable.create { (subscriber) -> Disposable in
            
                task.downloadProgress(closure: { (progress) in
                    subscriber.onNext(.progress(x: progress.fractionCompleted))
                })
                .response { response in
                    
                    if let e = response.error {
                        subscriber.onError(e)
                        return
                    }
                    
                    guard let path = response.destinationURL else {
                        fatalError("Download task has neither error nor result. \(response)")
                    }
                    
                    subscriber.onNext(.data(x: path))
                    subscriber.onCompleted()
                }
            
            return Disposables.create {
                task.cancel()
            }
        
        }
    
        return (o, task)
    }
    
}
