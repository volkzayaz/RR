//
//  PageContentControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/15/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import WebKit
import Alamofire
import RxSwift

final class PageContentControllerViewModel: NSObject, PageContentViewModel {

    enum PageCommandType: String {
        case getInitialData
        case getSrtsPreviews
        case playNow
        case playNext
        case playLast
        case replace
        case setForceExplicit
        case toggleArtistFollowing
        case log
        case error
        case unknown
        
        case downloadAlbum
    }

    // MARK: - Private properties -

    private(set) weak var delegate: PageContentViewModelDelegate?
    private(set) weak var router: PageContentRouter?

    private(set) var application: Application
    private(set) var pagesLocalStorage: PagesLocalStorageService

    private(set) var page: Page
    var url: URL? { return page.url }
    var snapshotImage: UIImage? { return self.pagesLocalStorage.snapshotImage(for: self.page) }
    var isNeedUpdateSnapshotImage: Bool { return self.pagesLocalStorage.containsSnapshotImage(for: self.page) == false }

    private(set) var requestedTimeTrackIds: [Int]
    private(set) var handledCommandsNames: [String]

    // MARK: - Lifecycle -

    deinit {
        print("PageContentControllerViewModel deinit")
        
    }

    init(router: PageContentRouter, page: Page, application: Application, pagesLocalStorage: PagesLocalStorageService) {
        self.router = router
        self.page = page
        self.application = application
        self.pagesLocalStorage = pagesLocalStorage
        self.requestedTimeTrackIds = []
        self.handledCommandsNames = [PageCommandType.getInitialData.rawValue,
                                     PageCommandType.getSrtsPreviews.rawValue,
                                     PageCommandType.playNow.rawValue,
                                     PageCommandType.playLast.rawValue,
                                     PageCommandType.playNext.rawValue,
                                     PageCommandType.replace.rawValue,
                                     PageCommandType.setForceExplicit.rawValue,
                                     PageCommandType.toggleArtistFollowing.rawValue,
                                     PageCommandType.log.rawValue,
                                     PageCommandType.error.rawValue,
                                    PageCommandType.downloadAlbum.rawValue
        ]
    }

    func load(with delegate: PageContentViewModelDelegate) {
        self.delegate = delegate

        let iOSWebViewScriptSource = "let iphoneWebView = true;"
        let iOSWebViewScript = WKUserScript(source: iOSWebViewScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)

        let playerDisabledScriptSource = "let style = document.createElement('style'); style.innerHTML = '.rr-player-root {display: none !important}';setTimeout(()=>document.head.appendChild(style),0);"
        let playerDisabledScript = WKUserScript(source: playerDisabledScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)

        let scripts = [iOSWebViewScript, playerDisabledScript]

//        #if DEBUG
//            let consoleLogSource = """
//                console.log = function(str){
//                    window.webkit.messageHandlers.log.postMessage(str);}
//            """
//            let consoleLogScript = WKUserScript(source: consoleLogSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
//            scripts.append(consoleLogScript)
//
//        let consolErrorSource = """
//                console.error = function(str){
//                    window.webkit.messageHandlers.error.postMessage(str);}
//            """
//        let consoleErrorScript = WKUserScript(source: consolErrorSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
//        scripts.append(consoleErrorScript)
//
//        #endif

        let commandHandlers = self.handledCommandsNames.reduce([String : WKScriptMessageHandler]()) { (result, commandName) -> [String : WKScriptMessageHandler] in
            var result = result
            result[commandName] = self
            return result
        }


        self.delegate?.configure(with: scripts, commandHandlers: commandHandlers)

        self.delegate?.reloadUI()

//        self.delegate?.evaluateJavaScript(javaScriptString: playerDisabledScriptSource, completionHandler: nil)

        

    }

    func snapshotRect(for bounds: CGRect) -> CGRect {

        return CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: bounds.width, height: bounds.width * self.pagesLocalStorage.pageSnapshotAspectRatio))
    }

    func save(snapshotImage: UIImage) {
        self.pagesLocalStorage.save(snapshotImage: snapshotImage, for: self.page)
    }

    func webViewFailed(with error: Error) {
        self.router?.pageFailed(with: error)
    }

    func updateUserOnPage() {
        let user = appStateSlice.user
        
        let data = try! JSONEncoder().encode(user)
        
        guard let stringData = String(data: data, encoding: .utf8) else { return }
        
        let javaScriptString = "window.externalDataSource.updateUser('" + stringData + "')"
        
        //            print("updateUserOnPage javaScriptString: \(javaScriptString)")
        
        self.delegate?.evaluateJavaScript(javaScriptString: javaScriptString, completionHandler: nil)
        
    }

    func updateCurrentTrackStateOnPage() {
        guard let track = appStateSlice.currentTrack?.track else { return }

        do {
            let pageTrackState = PageTrackState(trackId: track.id,
                                                isPlaying: appStateSlice.player.currentItem?.state.isPlaying ?? false)
            let jsonDat = try JSONEncoder().encode(pageTrackState)
            guard let stringData = String(data: jsonDat, encoding: .utf8) else { return }

            let javaScriptString = "window.externalDataSource.updateCurrentTrackState('" + stringData + "')"

//            print("updateCurrentTrackStateOnPage javaScriptString: \(javaScriptString)")

            self.delegate?.evaluateJavaScript(javaScriptString: javaScriptString, completionHandler: nil)

        } catch {

        }
    }

    func updatePreviewOptOnPage(tracksTotalPlayMSeconds: [Int : UInt64]) {

        do {
            let jsonDat = try JSONEncoder().encode(tracksTotalPlayMSeconds)
            guard let stringData = String(data: jsonDat, encoding: .utf8) else { return }

            let javaScriptString = "window.externalDataSource.updatePreviewOpt('" + stringData + "')"

//            print("updatePreviewOptOnPage javaScriptString: \(javaScriptString)")

            self.delegate?.evaluateJavaScript(javaScriptString: javaScriptString, completionHandler: nil)

        } catch {

        }

    }

    private func play(tracks: [Track]) {
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks, style: .now))
    }
    
    private func addToPlayerPlaylist(tracks: [Track], at position: RRPlayer.AddStyle) {
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks, style: position))
    }
    
    private func replacePlayerPlaylist(with tracks: [Track]) {
        Dispatcher.dispatch(action: ReplaceTracks(with: tracks))
    }

}

extension PageContentControllerViewModel: WKScriptMessageHandler {

    func getTracks(from jsonString: String) -> [Track]? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }

        do {
            let tracks = try JSONDecoder().decode([Track].self, from: jsonData)
            return tracks
        } catch {
            print("Bad Tracks JSON : \(jsonString)")
        }

        return nil
    }

    func getTrackIds(from jsonString: String) -> [Int]? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }

        do {
            let trackIds = try JSONDecoder().decode([Int].self, from: jsonData)
            return trackIds
        } catch {
            print("Bad TrackIds JSON : \(jsonString)")
        }

        return nil
    }

    func getTrackForceToPlayState(from jsonString: String) -> PageTrackForceToPlayState? {

        guard let jsonData = jsonString.data(using: .utf8) else { return nil }

        do {
            let trackForceToPlayState = try JSONDecoder().decode(PageTrackForceToPlayState.self, from: jsonData)
            return trackForceToPlayState
        } catch {
            print("Bad PageTrackForceToPlayState JSON : \(jsonString)")
        }

        return nil

    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {

        
        //            print("didReceive message name: \(message.name)")
        
        let commandType = PageCommandType(rawValue: message.name) ?? .unknown
        
        switch commandType {
            
        case .getInitialData:
            self.updateUserOnPage()
            self.updateCurrentTrackStateOnPage()
            
        case .getSrtsPreviews:
            //                print("getSrtsPreviews")
            guard let jsonString = message.body as? String, let trackIds = self.getTrackIds(from: jsonString) else { return }
            self.requestedTimeTrackIds = trackIds
            
            var trackIdsToRequest: [Int] = []
            var tracksTotalPlayMSeconds: [Int : UInt64] = [:]
            
            for trackId in trackIds {
                fatalError("Unimplemented preview logic")
                //                    guard let trackTotalPlayMSeconds = self.player.totalPlayMSeconds(for: trackId) else { trackIdsToRequest.append(trackId); continue}
                //                    tracksTotalPlayMSeconds[trackId] = trackTotalPlayMSeconds
            }
            
            if tracksTotalPlayMSeconds.isEmpty == false {
                self.updatePreviewOptOnPage(tracksTotalPlayMSeconds: tracksTotalPlayMSeconds)
            }
            
            if trackIdsToRequest.isEmpty == false {
                //                    self.player.trackingTimeRequest(for: trackIdsToRequest)
            }
            
        case .playNow:
            //                print("playNow!!!!")
            guard let jsonString = message.body as? String, let tracks = self.getTracks(from: jsonString) else { return }
            
            //                print("playNow: \(tracks)")
            
            self.play(tracks: tracks)
            
        case .playNext:
            //                print("playNext!!!!")
            guard let jsonString = message.body as? String, let tracks = self.getTracks(from: jsonString) else { return }
            //                print("playNext: \(tracks)")
            self.addToPlayerPlaylist(tracks: tracks, at: .next)
            
        case .playLast:
            //                print("playLast!!!!")
            guard let jsonString = message.body as? String, let tracks = self.getTracks(from: jsonString) else { return }
            //                print("playLast: \(tracks)")
            self.addToPlayerPlaylist(tracks: tracks, at: .last)
            
        case .replace:
            //                print("replace!!!!")
            guard let jsonString = message.body as? String, let tracks = self.getTracks(from: jsonString) else { return }
            //                print("replace: \(tracks)")
            self.replacePlayerPlaylist(with: tracks)
            
        case .setForceExplicit:
            //                print("setForceExplicit!!!!")
            guard let jsonString = message.body as? String, let trackForceToPlayState = self.getTrackForceToPlayState(from: jsonString) else { return }
            
            //                print("setForceExplicit: \(trackForceToPlayState)")
            
            UserManager.allowPlayTrackWithExplicitMaterial(trackId: trackForceToPlayState.trackId,
                                                           shouldAllow: trackForceToPlayState.isForcedToPlay).subscribe()
            
        case .toggleArtistFollowing:
            
            guard let artistId = message.body as? String else { return }
            guard appStateSlice.user.isGuest else { self.router?.navigateToAuthorization(); return }
            
            UserManager.follow(shouldFollow: !appStateSlice.user.isFollower(for: artistId),
                                    artistId: artistId)
                .subscribe(onError: { [weak self] (error) in
                    self?.delegate?.show(error: error)
                })
            
        case .downloadAlbum:
            
            guard let albumId = message.body as? Int else { return }
            
            AlbumRequest.details(x: albumId)
                .rx.response(type: BaseReponse<Album>.self)
                .subscribe(onSuccess: { [weak r = self.router] d in
                    r?.showDownloadAlbum(album: d.data)
                    }, onError: { [weak d = self.delegate] e in
                        d?.show(error: e)
                })
            
        case .log: print("Log: \(message.body)")
        case .error: print("Error: \(message.body)")
            
            
        case .unknown: print("Unknown page command : \(message.name) body: \(message.body)")
        }

        
    }
}


extension PageContentControllerViewModel {

    func player(didUpdateTracksTotalPlayMSeconds tracksTotalPlayMSeconds: [Int : UInt64]) {
        self.updatePreviewOptOnPage(tracksTotalPlayMSeconds: tracksTotalPlayMSeconds)
    }

    func player(didChangePlayState isPlaying: Bool) {
        self.updateCurrentTrackStateOnPage()
    }

    func player(didChangePlayerItem playerItem: Int/*PlayerItem?*/) {
        self.updateCurrentTrackStateOnPage()
    }
}

extension PageContentControllerViewModel {

    func application(_ application: Application, didChange user: User) {
        self.updateUserOnPage()
    }

    func application(_ application: Application, didChangeUserProfile userProfile: UserProfile) {
        self.updateUserOnPage()
    }

    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings) {
        self.updateUserOnPage()
    }

    func application(_ application: Application, didChangeUserProfile forceToPlayTracksIds: [Int], with trackForceToPlayState: TrackForceToPlayState) {
        self.updateUserOnPage()
    }

    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        self.updateUserOnPage()
    }

    func application(_ application: Application, didChangeUserProfile skipAddonsArtistsIds: [String], with skipArtistAddonsState: SkipArtistAddonsState) {
        self.updateUserOnPage()
    }

    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int]) {
        self.updateUserOnPage()
    }

    func application(_ application: Application, didChangeUserProfile tracksLikeStates: [Int : Track.LikeStates], with trackLikeState: TrackLikeState) {
        self.updateUserOnPage()
    }

}

