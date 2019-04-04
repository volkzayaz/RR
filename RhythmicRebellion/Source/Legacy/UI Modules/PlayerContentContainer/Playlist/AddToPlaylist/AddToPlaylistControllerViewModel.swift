//
//  AddToPlaylistControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import UIKit

class AddToPlaylistControllerViewModel: AddToPlaylistViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: AddToPlaylistViewModelDelegate?
    private(set) weak var router: AddToPlaylistRouter?
    private(set) var application: Application
    private(set) var restApiService : RestApiService
    
    private(set) var playlists: [FanPlaylist] = [FanPlaylist]()
    private let excludedPlaylists: [FanPlaylist]
    private(set) var createPlaylistVM : CreatePlaylistTableViewCellViewModel
    
    // MARK: - Lifecycle -

    deinit {
        
    }

    init(router: AddToPlaylistRouter, application: Application, restApiService: RestApiService, excludedPlaylists: [FanPlaylist]) {
        self.router = router
        self.application = application
        self.restApiService = restApiService

        self.excludedPlaylists = excludedPlaylists

        createPlaylistVM = CreatePlaylistTableViewCellViewModel()
    }

    func load(with delegate: AddToPlaylistViewModelDelegate) {
        self.delegate = delegate
        self.loadPlaylists()
        self.delegate?.reloadUI()

        
    }
    
    func loadPlaylists() {
        
        PlaylistRequest.fanList
            .rx.response(type: [FanPlaylist].self)
            .subscribe(onSuccess: { [weak self] (playlists) in
                self?.playlists = playlists
                self?.delegate?.reloadUI()
                }, onError: { [weak self] (error) in
                    self?.delegate?.show(error: error, completion: { [weak self] in  self?.delegate?.reloadUI() })
            })
        
    }
    
    func numberOfItems() -> Int {
        return self.playlists.count + 1
    }
    
    func object(at indexPath: IndexPath) -> AddToPlaylistTableViewCellViewModel? {
        if indexPath.row == 0 {            
            createPlaylistVM.createPlaylistCallback = {[weak self] name in
                if let newName = name, !newName.isEmpty {
                    self?.createPlaylist(with: newName)
                }
            }
            return createPlaylistVM
        }
        
        let playlist =  self.playlists[indexPath.row - 1]
        return PlaylistTableViewCellViewModel(playlist: playlist)
    }

    func selectObject(at indexPath: IndexPath) {
        guard indexPath.row != 0 else { return }

        let playlist =  self.playlists[indexPath.row - 1]
        self.select(playlist: playlist)
    }

    open func select(playlist: FanPlaylist) {
        fatalError("select(playlist) showld be implemented in subclasses")
    }


    func createPlaylist(with name: String) {
        self.delegate?.showProgress()
        PlaylistManager.createPlaylist(with: name)
            .subscribe(onSuccess: { [weak self] playlist in
                
                self?.delegate?.hideProgress()
                
                self?.playlists.insert(playlist, at: 0)
                self?.delegate?.reloadUI()
                self?.select(playlist: playlist)

                
            }, onError: { [weak self] (error) in
                
                self?.delegate?.hideProgress()
                
                self?.delegate?.show(error: error)
            })
        
    }

    func cancel() {
        createPlaylistVM.createPlaylistCallback = nil
        router?.dismiss()
    }
}

extension AddToPlaylistControllerViewModel {

    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState) {
        guard let playlist = self.playlists.filter( { return $0.id == fanPlaylistState.id } ).first,
            let playlistIndex = self.playlists.index(of: playlist) else {

                guard let updatedPlaylist = fanPlaylistState.playlist else { return }
                self.playlists.append(updatedPlaylist)
                self.delegate?.reloadUI()
                return
        }

        if let updatedPlaylist = fanPlaylistState.playlist {
            self.playlists[playlistIndex] = updatedPlaylist
        } else {
            self.playlists.remove(at: playlistIndex)
        }

        self.delegate?.reloadUI()
    }
}

class PlaylistTableViewCellViewModel : AddToPlaylistTableViewCellViewModel {
    private let playlist : FanPlaylist
    
    init(playlist: FanPlaylist) {
        self.playlist = playlist
    }
    
    func configure(cell: UITableViewCell) {
        guard let playlistCell = cell as? AddToPlaylistTableViewCell else { return }
        playlistCell.playlistTitle.text = playlist.name
        playlistCell.playlistThumbnail.layer.cornerRadius = 6
    }
    
    var identifier: String {
        return "playlistCellId"
    }
}

class CreatePlaylistTableViewCellViewModel : AddToPlaylistTableViewCellViewModel {
    var createPlaylistCallback: ((String?)->())?
    
    var identifier: String {
        return "addPlaylistCellId"
    }
    
    func configure(cell: UITableViewCell) {
        guard let createCell = cell as? CreatePlaylistTableViewCell else { return }
        createCell.addImage.layer.borderColor = UIColor(red: 0.39, green: 0.39, blue: 0.6, alpha: 1.0).cgColor
        createCell.addImage.layer.borderWidth = 1
        createCell.addImage.layer.cornerRadius = 6
        
        createCell.nameEditingFinishedCallback = {[weak self] name in
            createCell.playlistNametextField.text = nil
            self?.createPlaylistCallback?(name)
        }
    }
}
