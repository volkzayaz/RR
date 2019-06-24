//
//  AlbumPlaylistProvider.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/24/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct AlbumPlaylistProvider: PlaylistProvider, Playlist {
    
    let album: Album
    let instantDownload: Bool
    
    func provide() -> Observable<[TrackRepresentation]> {
        return ArtistRequest.albumRecords(album: album)
            .rx.response(type: BaseReponse<[Track]>.self)
            .map { $0.data.enumerated().map(TrackRepresentation.init) }
            .asObservable()
    }
    
    ///surrogate getter
    var playlist: Playlist {
        return self
    }
    
    var id: Int { return album.id }
    var name: String { return album.name }
    var thumbnailURL: URL? {
        guard let x = album.image.simpleURL else { return nil }
        
        return URL(string: x)
    }
    
    var isDefault: Bool { return false }
    var description: String? { return nil }
    var title: String? { return nil }
    var isFanPlaylist: Bool { return false }
    
}

extension AlbumPlaylistProvider: DownloadablePlaylistProvider {
    
    var downloadable: Maybe<Downloadable> {
        
        struct DownloadableAlbum: Downloadable {
            let fileName: String
            let url: URL
            func asURL() throws -> URL { return url }
        }
        
        let x = album.name
        return AlbumRequest.downloadLink(album: album)
            .rx.response(type: BaseReponse<String>.self)
            .map {
                DownloadableAlbum( fileName: "\(x).zip",
                    url: URL(string: $0.data)! )
                
        }
        
    }
    
}
