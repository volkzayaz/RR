//
//  DownloadViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/15/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import DownloadButton

extension DownloadViewModel {
    
    var downloadPercent: Driver<CGFloat> {
        return dataState.asDriver().map { x -> CGFloat? in
            guard let state = x,
                case .progress(let p) = state else {
                    return nil
            }
            
            return CGFloat(p)
            }
            .notNil()
    }
    
    var state: Driver<PKDownloadButtonState> {
        
        let progress = dataState.asDriver().notNil().map { x -> PKDownloadButtonState in
            
            switch x {
            case .data(_):     return .downloaded
            case .progress(_): return .downloading
            case .error(_):    return .startDownload
            case .initialise:  return .pending
            }
            
        }
        
        return progress.startWith(.startDownload)
            .distinctUntilChanged()
        
    }
    
}

struct DownloadViewModel {
    
    let dataState: BehaviorRelay<DownloadStatus<URL>?> = BehaviorRelay(value: nil)
    fileprivate let downloadManager = MulticastDownloadManager.default
    
    fileprivate let bag = DisposeBag()
    
    let downloadable: Downloadable
    
    ///@param instantStart - viewModel attempts to instantly start downloading resource at |remoteURL|
    ///                      unless it is already been downloading or downloaded
    init(downloadable: Downloadable, instantStart: Bool = false) {
        
        self.downloadable = downloadable
        
        downloadManager.downloadStatus(for: downloadable)
            .bind(to: dataState)
            .disposed(by: bag)
        
        if case .data(_)? = dataState.value {
            return
        }

        if instantStart {
            download()
        }
        
    }
    
    func download() {
        downloadManager.start(for: downloadable)
    }
    
    func cancelDownload() {
        downloadManager.cancel(for: downloadable)
    }
    
}
