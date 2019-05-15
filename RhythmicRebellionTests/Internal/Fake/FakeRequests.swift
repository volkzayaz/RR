//
//  FakeRequests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Mocker

struct FakeRequests {
    
    struct Addons {
        
        static func registerAdvertisementAddon(with url: URL) {
            
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.advertisement
                ]).register()
        }
        
        static func registerSongIntroductionAddon(with url: URL) {
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.songIntroduction
                ]).register()
        }
        
        static func registerSongCommentaryAddon(with url: URL) {
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.songCommentary
                ]).register()
        }
        
        static func registerArtistBIOAddon(with url: URL) {
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.artistBIO
                ]).register()
        }
        
        static func registerArtistAnnouncementsAddon(with url: URL) {
            Mock(url: url, dataType: .json, statusCode: 200, data: [
                Mock.HTTPMethod.get : FakeData.Addon.artistAnnouncements
                ]).register()
        }
    }
    
    
    static func registerMockRequestArtist(with url: URL) {
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            Mock.HTTPMethod.get : FakeData.artist
            ]).register()
    }
}
