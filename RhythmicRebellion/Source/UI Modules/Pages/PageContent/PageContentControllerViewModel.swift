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
    }

    // MARK: - Private properties -

    private(set) weak var delegate: PageContentViewModelDelegate?
    private(set) weak var router: PageContentRouter?

    private(set) var application: Application
    private(set) var player: Player
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
        self.player.removeWatcher(self)
        self.application.removeWatcher(self)
    }

    init(router: PageContentRouter, page: Page, application: Application, player: Player, pagesLocalStorage: PagesLocalStorageService) {
        self.router = router
        self.page = page
        self.application = application
        self.player = player
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
                                     PageCommandType.error.rawValue]
    }

    func load(with delegate: PageContentViewModelDelegate) {
        self.delegate = delegate

        let iOSWebViewScriptSource = "let iphoneWebView = true;"
        let iOSWebViewScript = WKUserScript(source: iOSWebViewScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: true)

        let playerDisabledScriptSource = "let style = document.createElement('style'); style.innerHTML = '.rr-player-root {display: none !important}';setInterval(()=>document.head.appendChild(style),0);"
        let playerDisabledScript = WKUserScript(source: playerDisabledScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)

        var scripts = [iOSWebViewScript, playerDisabledScript]

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

        self.application.addWatcher(self)
        self.player.addWatcher(self)

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
        guard let user = self.application.user else { return }

        do {

            let data: Data

            switch user {
            case let fanUser as FanUser: data = try JSONEncoder().encode(fanUser)
            case let guestUser as GuestUser: data = try JSONEncoder().encode(guestUser)
            default: fatalError("Unknown user type")
            }

            guard let stringData = String(data: data, encoding: .utf8) else { return }

            let javaScriptString = "window.externalDataSource.updateUser('" + stringData + "')"

//            print("updateUserOnPage javaScriptString: \(javaScriptString)")

            self.delegate?.evaluateJavaScript(javaScriptString: javaScriptString, completionHandler: nil)
        } catch {

        }
    }

    func updateCurrentTrackStateOnPage() {
        guard let track = self.player.currentItem?.playlistItem.track else { return }

        do {
            let pageTrackState = PageTrackState(trackId: track.id, isPlaying: self.player.isPlaying)
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
        guard tracks.isEmpty == false else { return }

        self.player.add(tracks: tracks, at: .next, completion: { [weak self] (playlistItems, error) in
            guard let playlistItem = playlistItems?.first else {
                guard let error = error else { return }
                self?.delegate?.show(error: error)
                return
            }

            self?.player.performAction(.playNow, for: playlistItem, completion: { [weak self] (error) in
                guard let error = error else { return }
                self?.delegate?.show(error: error)
            })
        })
    }

    private func addToPlayerPlaylist(tracks: [Track], at position: Player.PlaylistPosition) {
        guard tracks.isEmpty == false else { return }

        self.player.add(tracks: tracks, at: position, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })
    }

    private func replacePlayerPlaylist(with tracks: [Track]) {
        guard tracks.isEmpty == false else { return }

        self.player.replace(with: tracks, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })
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

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        do {

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
                    guard let trackTotalPlayMSeconds = self.player.totalPlayMSeconds(for: trackId) else { trackIdsToRequest.append(trackId); continue}
                    tracksTotalPlayMSeconds[trackId] = trackTotalPlayMSeconds
                }

                if tracksTotalPlayMSeconds.isEmpty == false {
                    self.updatePreviewOptOnPage(tracksTotalPlayMSeconds: tracksTotalPlayMSeconds)
                }

                if trackIdsToRequest.isEmpty == false {
                    self.player.trackingTimeRequest(for: trackIdsToRequest)
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

                if trackForceToPlayState.isForcedToPlay {
                    self.application.allowPlayTrackWithExplicitMaterial(trackId: trackForceToPlayState.trackId)
                } else {
                    self.application.disallowPlayTrackWithExplicitMaterial(trackId: trackForceToPlayState.trackId)
                }

            case .toggleArtistFollowing:

                guard let artistId = message.body as? String else { return }
                guard let fanUser = self.application.user as? FanUser else { self.router?.navigateToAuthorization(); return }
                
                let followingCompletion: (Result<[String]>) -> Void = { [weak self] (followingResult) in

                    switch followingResult {
                    case .failure(let error):
                        self?.delegate?.show(error: error)
                    default: break
                    }
                }

                if fanUser.isFollower(for: artistId) {
                    self.application.unfollow(artistId: artistId, completion: followingCompletion)
                } else {
                    self.application.follow(artistId: artistId, completion: followingCompletion)
                }

            case .log: print("Log: \(message.body)")
            case .error: print("Error: \(message.body)")


            case .unknown: print("Unknown page command : \(message.name) body: \(message.body)")
            }

        } catch {

        }
    }
}


extension PageContentControllerViewModel: PlayerObserver {

    func player(player: Player, didUpdateTracksTotalPlayMSeconds tracksTotalPlayMSeconds: [Int : UInt64]) {
        self.updatePreviewOptOnPage(tracksTotalPlayMSeconds: tracksTotalPlayMSeconds)
    }

    func player(player: Player, didChangePlayState isPlaying: Bool) {
        self.updateCurrentTrackStateOnPage()
    }

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {
        self.updateCurrentTrackStateOnPage()
    }
}

extension PageContentControllerViewModel: ApplicationObserver {

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

