//
//  FakeRequest.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Mocker
@testable import RhythmicRebellion

struct FakeRequest {
    
    struct Addons {
        
        static func registerAdvertisementAddon(withTrackIDs ids: [Int]) {
            let url = try! TrackRequest.addons(trackIds: ids).asURLRequest().url!
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.advertisement
                ]).register()
        }
        
        static func registerSongIntroductionAddon(withTrackIDs ids: [Int]) {
            let url = try! TrackRequest.addons(trackIds: ids).asURLRequest().url!
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.songIntroduction
                ]).register()
        }
        
        static func registerSongCommentaryAddon(withTrackIDs ids: [Int]) {
            let url = try! TrackRequest.addons(trackIds: ids).asURLRequest().url!
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.songCommentary
                ]).register()
        }
        
        static func registerArtistBIOAddon(withTrackIDs ids: [Int]) {
            let url = try! TrackRequest.addons(trackIds: ids).asURLRequest().url!
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.artistBIO
                ]).register()
        }
        
        static func registerArtistAnnouncementsAddon(withTrackIDs ids: [Int]) {
            let url = try! TrackRequest.addons(trackIds: ids).asURLRequest().url!
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.artistAnnouncements
                ]).register()
        }
    }
    
    struct Artist {
        
        static func registerMockRequestArtist(artistId id: String) {
            let url = try! TrackRequest.artist(artistId: id).asURLRequest().url!
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Artist.default
                ]).register()
        }
    }
    
    struct Lyrics {
        
        static func registerMockRequestLyrics(track: Track) {
            let url = try! TrackRequest.lyrics(track: track).asURLRequest().url!
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Lyrics.default
                ]).register()
        }
    }
}
