//
//  RRPlayer.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

class RRPlayer: NSObject {
    
    let webSocket: WebSocketService
    let audioPlayer = AudioPlayer()
    
    init(webSocket: WebSocketService) {
        self.webSocket = webSocket
        
        super.init()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            
            webSocket.connect(with: Token(token: DataLayer.get.application.user!.wsToken,
                                          isGuest: DataLayer.get.application.user!.isGuest))
            
        }
        
        
        bind()
        bindWebSocket()
    }
}

////UI initiated
extension RRPlayer {

    func play() {
        
        ///TODO: investiate memmory leak upon play/pause cycles
        
        Dispatcher.dispatch(action: AudioPlayer.Play())
    }
    
    func pause() {
        Dispatcher.dispatch(action: AudioPlayer.Pause())
    }
    
    func flip() {
        Dispatcher.dispatch(action: AudioPlayer.Switch())
    }
 
    func skipForward() {
        Dispatcher.dispatch(action: ProceedToNextItem())
    }
    
    func skipBack() {
        Dispatcher.dispatch(action: GetBackToPreviousItem())
    }
    
    func clear() {
        
    }
    
    enum AddStyle {
        case now, next, last
    }
    func add(tracks: [Track], type: AddStyle) {
        Dispatcher.dispatch(action: AddTracksToNowPlaying(tracks: tracks, style: type))
    }
    
    func remove(track: OrderedTrack) {
        Dispatcher.dispatch(action: RemoveTrack(orderedTrack: track))
    }
    
    func seek(to fraction: Float) {
        Dispatcher.dispatch(action: ScrubToFraction(fraction: fraction))
    }
    
    func `switch`(to track: OrderedTrack) {
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: track, shouldPlayImmidiatelly: true))
    }
    
}

///Push state into webSocket
extension RRPlayer {
    
    func bind() {

        /////-----
        ////Syncing using webSocket
        /////-----
        
        /// sync player state
        appState.map { $0.player.currentItem?.state }
            .notNil()
            .filter { $0.isOwn }
            .drive(onNext: { (x) in
                
                print("Sending out trackState for syncing with webSocket: \(x)")
                
                ///self.webSocket.sendCommand(command: WebSocketCommand.setTrackState(trackState: x))
            })
            .disposed(by: rx.disposeBag)
        
        /// sync playlist order (insert/delete/create/flush)
        appState.map { $0.player.lastPatch }
            .distinctUntilChanged()
            .notNil()
            .filter { $0.isOwn }
            .filter { _ in true } ///TODO: here odd logic with filtering out masterSendDate should be present
                                  ///////some cool logic about skipping such requests
                                  ///guard Date().timeIntervalSince(self.isMasterStateSendDate) > 1.0 else { /*print("BadTime");*/ return }
                                  ////take into account Hash of this state
            .drive(onNext: { (x) in
                
                print("Sending out patch for syncing with webSocket: \(x.patch)")
                //self.webSocket.sendCommand(command: WebSocketCommand.updatePlaylist(playlistItemsPatches: [String : PlayerPlaylistItemPatch?]))
                
            })
            .disposed(by: rx.disposeBag)
        
        ////sync current track ID
        appState.map { $0 }
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
        /// TODO: we should not send out commands for actions that are not our own
        ///.filter { $0.isOwn }
            .drive(onNext: { (state) in

                guard let orderedTrack = state.currentTrack else {
                    return
                }
                
                let t = TrackId(id: orderedTrack.track.id, key: orderedTrack.orderHash)
                
                print("Sending out currentTrackID for syncing with webSocket: \(t)")
                //self.webSocket.sendCommand(command: .setCurrentTrack(trackId: TrackId(id: id, key: hash)))
            })
            .disposed(by: rx.disposeBag)
        
        
        
        ////apply RR specific logic
        
        ////Enforce playback termination if user exceeded play time quota
        appState.map { $0.player }
            //.filter { $0.state.isOwn }
            .drive(onNext: { (x) in
                
                //print("Checking restricted time \(x)")
                
                ///Dispatcher.dispatch(action: CheckRestrictedTime(newState: x))
            })
            .disposed(by: rx.disposeBag)
        
        
    }
    
    func bindWebSocket() {
        
        webSocket.didReceivePlaylistPatch
            .subscribe(onNext: { (patch) in
                let action = ApplyReduxViewPatch( viewPatch: .init(isOwn: false,
                                                                   patch: patch) )
                
                Dispatcher.dispatch(action: action )
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveTracks
            .subscribe(onNext: { (tracks) in
                
                Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
                
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveCurrentTrack
            .subscribe(onNext: { (trackId) in
                
                guard let t = trackId else { return }
                
                Dispatcher.dispatch(action: PrepareNewTrackByHash(orderHash: t.key))
                
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveTrackState
            .subscribe(onNext: { (state) in
                
                Dispatcher.dispatch(action: ChangeTrackState(trackState: state))
                
            })
            .disposed(by: rx.disposeBag)

        webSocket.didReceiveTrackBlockState
            .subscribe(onNext: { (state) in
            
                Dispatcher.dispatch(action: ChangePlayerBlockState(isBlocked: state))
                
            })
            .disposed(by: rx.disposeBag)
        
    }
    
}



///////

struct CheckRestrictedTime: Action {
    
    //let newState: DaPlayerState.PlayingNow
    
    func perform(initialState: AppState) -> AppState {
        
//        guard case .track(let x)? = newState.musicType,
//              let allowedTime = initialState.allowedTimes[x.id],
//              allowedTime <= UInt(newState.state.progress) else {
//        
//            return initialState
//        }
//        
        fatalError("advance to next song, since we ellapsed listening time")
        
    }
}

////TODO: Proceed To Next Item and Prepare new track share a lot of logic
////especially in preparing addon.
////We need to extract this logic into unified concept
////without scattering Addons through multiple ActionCreators
struct ProceedToNextItem: ActionCreator {
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        guard var currentItem = initialState.player.currentItem,
              let currentTrack = initialState.currentTrack else {
            return .just(initialState)
        }
        
        var state = initialState
        
        if currentItem.addons.count > 0 {
            var addons = currentItem.addons
            let next = addons.removeFirst()
            
            currentItem.addons = addons
            
            state.player.currentItem = currentItem
            
            DataLayer.get.webSocketService.markPlayed(addon: next,
                                                      for: currentTrack.track)
            
            return .just(state)
        }
        else if let next = state.nextTrack {
            return PrepareNewTrack(orderedTrack: next,
                                   shouldPlayImmidiatelly: true).perform(initialState: state)
        }

        return .just(state)
    }
    
}

struct GetBackToPreviousItem: ActionCreator {
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        guard let currentHash = initialState.currentTrack?.orderHash,
              let previousItem = initialState.player.tracks.previous(before: currentHash) else {
            return .just(initialState)
        }
        
        return PrepareNewTrack(orderedTrack: previousItem,
                               shouldPlayImmidiatelly: true).perform(initialState: initialState)
    }
    
}

struct PrepareNewTrackByHash: ActionCreator {
    
    let orderHash: TrackOrderHash
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        guard let x = initialState.player.tracks[orderHash] else {
            fatalErrorInDebug(" Can't start playing track with order key: \(orderHash). It is not found in reduxView: \(initialState.player.tracks) ")
            return .just(initialState)
        }
        
        return PrepareNewTrack(orderedTrack: x,
                               shouldPlayImmidiatelly: false).perform(initialState: initialState)
    }
    
}

struct PrepareNewTrack: ActionCreator {
    
    let orderedTrack: OrderedTrack
    let shouldPlayImmidiatelly: Bool
    
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
        preState.player.currentItem?.state = .init(progress: 0,
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
                                                 state: .init(hash: WebSocketService.ownSignatureHash,
                                                              progress: 0,
                                                              isPlaying: self.shouldPlayImmidiatelly))
                
                return state
                
            }
            .startWith(preState)
        
    }
    
    func prepare(initialState: AppState) -> AppState {
        return AudioPlayer.Pause().perform(initialState: initialState)
    }
    
}

struct StoreTracks: Action {
    
    let tracks: [Track]
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        
        tracks.forEach { state.player.tracks.trackDump[$0.id] = $0 }
        
        return state
    }
    
}

struct ScrubToFraction: Action {
    
    let fraction: Float
    
    func perform(initialState: AppState) -> AppState {
        
        guard let secs = initialState.currentTrack?.track.audioFile?.duration else {
            return initialState
        }
        
        return AudioPlayer.Scrub(newValue: TimeInterval(secs) * Double(fraction)).perform(initialState: initialState)
    }
    
}

struct ChangeTrackState: Action {
    
    let trackState: TrackState
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        state.player.currentItem?.state = trackState
        return state
    }
    
}

struct AddTracksToNowPlaying: ActionCreator {
    
    let tracks: [Track]
    let style: RRPlayer.AddStyle
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        switch style {
        case .next:
            return InsertTracks(tracks: tracks, afterTrack: initialState.currentTrack, isOwnChange: true)
                .perform(initialState: initialState)
            
        case .now:
            
            return InsertTracks(tracks: tracks, afterTrack: initialState.currentTrack, isOwnChange: true)
                .perform(initialState: initialState)
                .flatMap { newState -> Observable<AppState> in
                    
                    guard let newCurrentTrack = newState.nextTrack ?? newState.firstTrack else {
                        return .just(newState)
                    }
                    
                    return PrepareNewTrack(orderedTrack: newCurrentTrack,
                                           shouldPlayImmidiatelly: true).perform(initialState: newState)
                }
            
        case .last:
            
            return InsertTracks(tracks: tracks, afterTrack: initialState.player.tracks.orderedTracks.last, isOwnChange: true)
                .perform(initialState: initialState)
            
        }
        
        
    }
    
}

struct RemoveTrack: ActionCreator {
    
    let orderedTrack: OrderedTrack
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        var maybeNextTrack: OrderedTrack? = nil
        if initialState.currentTrack == orderedTrack {
            maybeNextTrack = initialState.nextTrack ?? initialState.firstTrack
        }
        
        return DeleteTrack(track: orderedTrack, isOwnChange: true)
                .perform(initialState: initialState)
                .flatMap { newState -> Observable<AppState> in
                    
                    guard let c = maybeNextTrack else {
                        return .just(newState)
                    }
                    
                    return PrepareNewTrack(orderedTrack: c,
                                           shouldPlayImmidiatelly: initialState.player.currentItem?.state.isPlaying ?? false)
                        .perform(initialState: newState)
                    
                }
        
    }
    
}

struct ChangePlayerBlockState: Action {
    
    let isBlocked: Bool
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        state.player.isBlocked = isBlocked
        return state
    }
    
}
