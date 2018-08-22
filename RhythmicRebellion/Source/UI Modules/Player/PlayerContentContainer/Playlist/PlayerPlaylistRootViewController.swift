//
//  PlayerPlaylistRootViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

enum PlayerPlaylistSegment: Int {
    case nowPlaying
    case myPlaylists
    case following
}

final class PlayerPlaylistRootViewController: UIViewController {

    @IBOutlet weak var playlistTypeSegment: UISegmentedControl!
    @IBOutlet weak var nowPlayingContainerView: UIView!
    @IBOutlet weak var myPlaylistsContainerView: UIView!
    @IBOutlet weak var followingContainerView: UIView!

    // MARK: - Public properties -

    private(set) var viewModel: PlayerPlaylistRootViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PlayerPlaylistRootViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        viewModel.load(with: self)
        updateSegment()
    }

    // MARK: - Acitions -

    @IBAction func segmentedControlChanged(sender: UISegmentedControl) {
        updateChildren()
    }
    
    private func updateChildren() {
        guard let segmentType = PlayerPlaylistSegment.init(rawValue: playlistTypeSegment.selectedSegmentIndex) else { return }
        self.nowPlayingContainerView.isHidden = segmentType != .nowPlaying
        self.myPlaylistsContainerView.isHidden = segmentType != .myPlaylists
        self.followingContainerView.isHidden = segmentType != .following
    }
    
    private func updateSegment() {
        var lastSelectedIndex = playlistTypeSegment.selectedSegmentIndex
        playlistTypeSegment.removeAllSegments()
        playlistTypeSegment.insertSegment(withTitle: NSLocalizedString("Now Playing", comment: "Now playing playlist title"), at: 0, animated: false)
        
        if !viewModel.showOnlyNowPlaying {
            playlistTypeSegment.insertSegment(withTitle: NSLocalizedString("My Playlists", comment: "My Playlists playlist title"), at: 1, animated: false)
            playlistTypeSegment.insertSegment(withTitle: NSLocalizedString("Following", comment: "Following playlist title"), at: 2, animated: false)
        } else {
            lastSelectedIndex = 0
        }
        
        playlistTypeSegment.selectedSegmentIndex = lastSelectedIndex
        updateChildren()
    }
}

// MARK: - Router -
extension PlayerPlaylistRootViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}

extension PlayerPlaylistRootViewController: PlayerPlaylistRootViewModelDelegate {
    func refreshUI() {
        updateSegment()
    }
}
