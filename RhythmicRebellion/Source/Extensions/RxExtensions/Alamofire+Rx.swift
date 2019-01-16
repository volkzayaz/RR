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

enum DownloadStatus<T> {
    case initialise
    case progress(Double)
    case data(T)
    case error(Error)
}

extension Reactive where Base == DownloadRequest {
    
    func download(shouldUseRxErrors: Bool = false) -> Observable<DownloadStatus<URL>> {
        
        return Observable.create { (subscriber) -> Disposable in
            
            subscriber.onNext(.initialise)
            
            self.base.downloadProgress(closure: { (progress) in
                subscriber.onNext( .progress(progress.fractionCompleted) )
            })
            .response { response in
                if let e = response.error {
                    
                    if shouldUseRxErrors { subscriber.onError(e) }
                    else {
                        subscriber.onNext( .error(e) )
                        subscriber.onCompleted()
                    }
                    
                    return
                }
                
                guard let path = response.destinationURL else {
                    fatalError("Download task has neither error nor result. \(response)")
                }
                
                subscriber.onNext( .data( path ) )
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
