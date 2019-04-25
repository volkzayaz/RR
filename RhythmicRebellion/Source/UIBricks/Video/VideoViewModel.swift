//
//  VideoViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/25/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension VideoViewModel {
    
    var video1: Driver<String?> {
        return appState.map { $0.currentTrack?.track.videoURLStrings }
            .distinctUntilChanged()
            .map { state in
            if let x = state?[safe: 0]?.split(separator: "=").last {
                return String(x)
            }
            
            return nil
        }
    }
    
    var video2: Driver<String?> {
        return appState.map { $0.currentTrack?.track.videoURLStrings }
            .distinctUntilChanged()
            .map { state in
            if let x = state?[safe: 1]?.split(separator: "=").last {
                return String(x)
            }
            
            return nil
        }
    }
    
}

struct VideoViewModel : MVVM_ViewModel {
    
    /** Reference dependent viewModels, managers, stores, tracking variables...
     
     fileprivate let privateDependency = Dependency()
     
     fileprivate let privateTextVar = BehaviourRelay<String?>(nil)
     
     */
    
    init(router: VideoRouter) {
        self.router = router
        
        appState.map { $0.currentTrack?.track.videoURLStrings }
            .distinctUntilChanged()
            .drive(onNext: { (x) in
                print("Videos: \(x)")
            })
        
        /**
         
         Proceed with initialization here
         
         */
        
        /////progress indicator
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
    }
    
    let router: VideoRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension VideoViewModel {
    
    /** Reference any actions ViewModel can handle
     ** Actions should always be void funcs
     ** any result should be reflected via corresponding drivers
     
     func buttonPressed(labelValue: String) {
     
     }
     
     */
    
}
