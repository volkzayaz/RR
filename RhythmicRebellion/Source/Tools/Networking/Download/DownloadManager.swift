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

protocol Downloadable: URLConvertible {
    var fileName: String { get }
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
    
    func download(x: Downloadable) -> (Observable<DownloadStatus<URL>>, DownloadToken) {
        
        let fileURL = self.fileURL(for: x)
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let x = sessionManager.download(x, to: destination)
        let d = x.rx.download()

        return (d, x)

    }
    
    func fileURL(for x: Downloadable) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent(x.fileName)
    }
    
    ///clears download directory
    func clearArtifacts() {
        
        ///TODO: clear only folder beloning to this download manager
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for path in try! FileManager.default.contentsOfDirectory(atPath: documentsURL.path) {
            do {
                try FileManager.default.removeItem(at: documentsURL.appendingPathComponent(path) )
            }
            catch (let e) {
                print(e)
            }
        }
    }
    
}


class MulticastDownloadManager {

    static let `default` = MulticastDownloadManager(manager: DownloadManager.default)
    
    private let manager: DownloadManager
    private let bag = DisposeBag()
    
    init(manager: DownloadManager) {
        self.manager = manager
    }
    
    fileprivate let pipe: BehaviorSubject<(Downloadable, DownloadStatus<URL>)?> = BehaviorSubject(value: nil)
    
    ///TODO: wrap accesses into barier queue
    var tasks: [String: DownloadToken] = [:]
    
    func downloadStatus(for x: Downloadable) -> Observable<DownloadStatus<URL>> {
        
        let maybeURL = manager.fileURL(for: x)
        let fileExist = FileManager.default.fileExists(atPath: maybeURL.path)
        
        return pipe.asObservable()
            .startWith( fileExist ? (x, .data(maybeURL)) : nil )
            .notNil()
            .filter { x.fileName == $0.0.fileName }
            .map { $0.1 }
    }
    
    func start(for d: Downloadable) {
        
        ///quit if download is already in progress
        guard tasks[d.fileName] == nil else { return }
        
        let res = manager.download(x: d)
        
        tasks[d.fileName] = res.1
        
        ///binding download task to global pipe to share with all subscribers
        res.0.map { (d, $0) }
            .do(onCompleted: { [unowned self] in
                self.tasks.removeValue(forKey: d.fileName)
                if let x = self.pipe.unsafeValue, x.0.fileName == d.fileName, case .data(_) = x.1 {
                    ///clean pipe afterwards if we are the last to download
                    self.pipe.onNext(nil)
                }
            })
            .flatMapLatest {
                return Observable.just($0).concat(Observable.never())
            }
            .bind(to: pipe)
            .disposed(by: bag)
        
    }
    
    func pause(for d: Downloadable) {
        
        guard let task = tasks[d.fileName] else {
            return fatalErrorInDebug("Trying to pause download of \(try? d.asURL()). But MulticastDownloadManager does not contain download task for this url.")
        }
        
        task.pause()
    }
    
    func resume(for d: Downloadable) {
        
        guard let task = tasks[d.fileName] else {
            return fatalErrorInDebug("Trying to resume download of \(try? d.asURL()). But MulticastDownloadManager does not contain download task for this url.")
        }
        
        task.resume()
    }
    
    func cancel(for d: Downloadable) {
        
        guard let task = tasks[d.fileName] else {
            return fatalErrorInDebug("Trying to cancel download of \(try? d.asURL()). But MulticastDownloadManager does not contain download task for this url.")
        }
        
        task.cancel()
        
    }
}
