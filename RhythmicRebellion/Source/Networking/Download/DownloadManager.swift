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

//struct ProgressData {
//
//    let fractionCompleted: Double
//    let speed: Int64
//
//    static var empty: ProgressData {
//        return ProgressData(fractionCompleted: 0,
//                            speed: 0)
//    }
//
//}

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
    
        let x = SessionManager(configuration: config)
        return x
    }()
    
    func download(x: URLConvertible) -> (Observable<ChunkedData<URL>>, DownloadToken) {
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(try! x.asURL().absoluteString)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let x = sessionManager.download(x, to: destination)
        
        let d = x.rx.download
        
        return (d, x)
//
//        let progress = d.map { (chunked) -> Progress? in
//                switch chunked {
//                case .data(_): return nil
//                case .progress(let x): return x
//                }
//            }
//            .notNil()
//            .buffer(timeSpan: 1, count: 100, scheduler: SerialDispatchQueueScheduler(qos: .default))
//            .map { samples in
//                return ProgressData(fractionCompleted: samples.last?.fractionCompleted ?? 0,
//                                    speed: samples.last?.totalUnitCount ?? 0 - (samples.first?.totalUnitCount ?? 0))
//            }
//            .map { ChunkedData<URL, ProgressData>.progress(x: $0) }
//
//        let data = d.map { (chunked) -> URL? in
//            switch chunked {
//            case .data(let x): return x
//            case .progress(_): return nil
//            }
//        }
//        .notNil()
//        .map { ChunkedData<URL, ProgressData>.data(x: $0) }
//
//        return (Observable.merge([progress, data]), x)
    }
    
}


class MulticastDownloadManager {
    
    static let `default` = MulticastDownloadManager(manager: DownloadManager.default)
    
    private let manager: DownloadManager
    private let bag = DisposeBag()
    
    init(manager: DownloadManager) {
        self.manager = manager
    }
    
    fileprivate let pipe: BehaviorSubject<(String, ChunkedData<URL>)?> = BehaviorSubject(value: nil)
    
    ///TODO: wrap accesses into barier queue
    var tasks: [String: DownloadToken] = [:]
    
    
    func downloadStatus(for url: String) -> Observable<ChunkedData<URL>> {
        return pipe.asObservable().notNil()
            .filter { url == $0.0 }
            .map { $0.1 }
    }
    
    func start(for url: String) {
        
        ///quit if download is already in progress
        guard tasks[url] == nil else { return }
        
        let res = manager.download(x: url)
        
        tasks[url] = res.1
        
        ///binding download task to global pipe to share with all subscribers
        res.0.map { (url, $0) }
            .silentCatch()
            .do(onCompleted: { [unowned self] in
                self.tasks.removeValue(forKey: url)
            })
            .bind(to: pipe)
            .disposed(by: bag)
        
    }
    
    func pause(for url: String) {
        
        guard let task = tasks[url] else {
            return fatalErrorInDebug("Trying to pause download of \(url). But MulticastDownloadManager does not contain download task for this url.")
        }
        
        task.pause()
    }
    
    func resume(for url: String) {
        
        guard let task = tasks[url] else {
            return fatalErrorInDebug("Trying to resume download of \(url). But MulticastDownloadManager does not contain download task for this url.")
        }
        
        task.resume()
    }
    
    func cancel(for url: String) {
        
        guard let task = tasks[url] else {
            return fatalErrorInDebug("Trying to cancel download of \(url). But MulticastDownloadManager does not contain download task for this url.")
        }
        
        task.cancel()
        
    }
}
