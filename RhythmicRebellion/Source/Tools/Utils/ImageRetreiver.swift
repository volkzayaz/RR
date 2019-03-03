//
//  ImageRetreiver.swift
//   
//
//  Created by Vlad Soroka on 3/1/16.
//  Copyright © 2016   All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

import Alamofire
import AlamofireImage

enum ImageRetreiveResult {
    case image(i: UIImage?)
    case progress(x: Double)
}

enum ImageRetreiverError: Error {
    
    case CorruptedDataDownloaded
    
}

/**
 *  @discussion - Utility for retreiving image by given URL in Rx-way
 *  downloaded image is cached and used on next calls to save up on Internet traffic
*/
extension ImageRetreiver {
    
    static func imageForURLWithoutProgress(url: String) -> Driver<UIImage?> {
        
        return self.imageForURL(url: url)
            .map { res -> UIImage? in
                switch res {
                case .image(let x): return x
                case .progress(_): return nil
                }
            }
        
    }
    
    static func imageForURLRequestWithoutProgress<T: URLRequestConvertible> (url: T) -> Driver<UIImage?> {
        
        return self.imageForURLReques(request: url)
            .map { res -> UIImage? in
                switch res {
                case .image(let x): return x
                case .progress(_): return nil
                }
            }
        
    }
    
}


struct ImageRetreiver {

    private static var imageCache: AutoPurgingImageCache {
        return imageDownloader.imageCache! as! AutoPurgingImageCache
    }
    
    private static let imageDownloader: ImageDownloader = {
        
        let cache = AutoPurgingImageCache(memoryCapacity: 100_000_000,
                                          preferredMemoryUsageAfterPurge: 60_000_000)
        
        let downloader = ImageDownloader(configuration: URLSessionConfiguration.default,
                                         downloadPrioritization: .lifo,
                                         maximumActiveDownloads: 4,
                                         imageCache: cache)
        
        return downloader
    }()
    
    static func imageForURL<T: URLConvertible> (url: T) -> Driver<ImageRetreiveResult> {
        
        var unwrappedURL: URL!
        do {
            unwrappedURL = try url.asURL()
        }
        catch {
            return Driver.just( .image(i: nil) )
        }
        
        let request = URLRequest(url: unwrappedURL)
        return imageForURLReques(request: request)
        
    }
    
    static func imageForURLReques<T: URLRequestConvertible>(request: T) -> Driver<ImageRetreiveResult> {
        
        return Observable.create { observer in
            
            let receipt = imageDownloader
                .download(request,
                          progress: { progress in
                            
                            observer.onNext( .progress(x: progress.fractionCompleted) )
                            
                          },
                          completion: { (response) in
                            if let error = response.result.error {
                                observer.onError(error)
                                return
                            }
                            
                            guard let image = response.result.value else {
                                
                                fatalError("Alamofiire response is neither error nor value. \(request). \(response)")
                                
                            }
                            
                            observer.onNext( .image(i: image) )
                            observer.onCompleted()
                            return
                            
                })
            
            
                return Disposables.create {
                    receipt?.request.cancel()
                }
            
            }
            .asDriver(onErrorJustReturn: .image(i: nil) )
    
    }
    
    static func cachedImageForKey(key: String) -> UIImage? {
    
        guard let url = URL(string: key) else {
            return nil
        }
        
        return imageCache.image(for: URLRequest(url: url) )
        
    }
    
    
    static func flushCache() {
        imageCache.removeAllImages()
    }
}
