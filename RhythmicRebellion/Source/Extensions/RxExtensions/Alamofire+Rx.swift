//
//  Alamofire+Rx.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import Alamofire
import RxSwift

extension Reactive where Base == DownloadRequest {
    
    var download: Observable<ChunkedData<URL>> {
        
        return Observable.create { (subscriber) -> Disposable in
            
                self.base.downloadProgress(closure: { (progress) in
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
                self.base.cancel()
            }
            
        }
        
    }
    
}

extension DownloadRequest {
    
    var rx: Reactive<DownloadRequest> {
        return Reactive(self)
    }
    
}
