//
//  PrepareNewTrack.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct PrepareNewTrack: ActionCreator {
    
    let orderedTrack: OrderedTrack
    let shouldPlayImmidiatelly: Bool
    let signatureHash: String
    
    init(orderedTrack: OrderedTrack,
         shouldPlayImmidiatelly: Bool,
         signatureHash: String = WebSocketService.ownSignatureHash) {
        
        self.orderedTrack = orderedTrack
        self.shouldPlayImmidiatelly = shouldPlayImmidiatelly
        self.signatureHash = signatureHash
        
    }
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        //        1) Собираемся проигрывать `trackID`
        //        2) Делаем `RestAPI player/audio-add-ons-for-tracks` & `RestAPI player/artist`
        //        3) Получаем набор `Array<Addon>`
        //        4) Делаем `WebSocket setBlock = true`
        //        5) Делаем `WebSocket. addons-checkAddons` с параметрами из шагов 1 и 3
        //        6) Получаем подмножество `Array<Addon>` из шага 3
        //        7) Сортируем подмножество из шага 7
        //        8) Посылаем `WebSocket. addons-playAddon`
        //        9) Играем Аддон
        //        10) Делаем `WebSocket setBlock = false`
        
        ///2
        let trackAddons = TrackRequest.addons(trackIds: [orderedTrack.track.id])
            .rx.response(type: AddonsForTracksResponse.self)
            .map { $0.trackAddons.first?.value ?? [] }
            .asObservable()
        
        let artistAddons = TrackRequest.artist(artistId: orderedTrack.track.artist.id)
            .rx.response(type: BaseReponse<[Artist]>.self)
            .map { $0.data.first?.addons ?? [] }
            .asObservable()
        
        ///before preapering new track we need to pause old track and rewind to point 0 secs
        var preState = initialState
        preState.player.currentItem?.state = .init(hash: signatureHash,
                                                   progress: 0,
                                                   isPlaying: false)
        
        ///3
        return Observable.combineLatest(trackAddons,
                                        artistAddons) { $0 + $1 }
            ///5, 6, 7
            .flatMap { addons -> Observable<[Addon]> in
                return DataLayer.get.webSocketService.filter(addons: addons, for: self.orderedTrack.track)
            }
            .map { addons -> AppState in
                
                var state = preState
                
                ///8
                if let x = addons.first {
                    DataLayer.get.webSocketService.markPlayed(addon: x,
                                                              for: self.orderedTrack.track)
                }
                
                ///9
                state.player.currentItem = .init(activeTrackHash: self.orderedTrack.orderHash,
                                                 addons: addons,
                                                 state: .init(hash: self.signatureHash,
                                                              progress: 0,
                                                              isPlaying: self.shouldPlayImmidiatelly))
                
                return state
                
            }
            .startWith(preState)
        
    }
    
}
