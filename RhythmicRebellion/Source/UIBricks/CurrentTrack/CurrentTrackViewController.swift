//
//  CurrentTrackViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/5/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class CurrentTrackViewController: UIViewController, MVVM_View {
    
    var viewModel: CurrentTrackViewModel!
    
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var trackArtistLabel: UILabel!
    
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    
    @IBOutlet weak var progressSlider: UISlider! {
        didSet {
            progressSlider.setThumbImage(R.image.thumb(), for: .normal)
            progressSlider.setThumbImage(R.image.thumb(), for: .highlighted)
        }
    }
    @IBOutlet weak var leftProgress: UILabel!
    @IBOutlet weak var rightProgress: UILabel!
    
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var nextUpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.rightProgress.drive(rightProgress.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.leftProgress.drive(leftProgress.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.progressFraction.drive(progressSlider.rx.value)
            .disposed(by: rx.disposeBag)
        
        viewModel.title.drive(trackNameLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.artist.drive(trackArtistLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.imageURL
            .flatMapLatest { ImageRetreiver.imageForURLWithoutProgress(url: $0) }
            .map { $0 ?? R.image.cover_placeholder() }
            .drive(trackImageView.rx.image)
            .disposed(by: rx.disposeBag)
        
        viewModel.isPlaying
            .map { $0 ? R.image.pause() : R.image.play() }
            .drive(playButton.rx.image(for: .normal))
            .disposed(by: rx.disposeBag)
        
        viewModel.isArtistFollowed
            .map { $0 ? R.image.follow() : R.image.follow_inactive() }
            .drive(starButton.rx.image(for: .normal))
            .disposed(by: rx.disposeBag)
        
        ////TODO: implement isBlocked UI
        
        viewModel.likeState.map { $0 == .liked }
            .map { $0 ? R.image.like_active() : R.image.like() }
            .drive(likeButton.rx.image(for: .normal))
            .disposed(by: rx.disposeBag)
        
        viewModel.likeState.map { $0 == .disliked }
            .map { $0 ? R.image.dislike_active() : R.image.dislike() }
            .drive(dislikeButton.rx.image(for: .normal))
            .disposed(by: rx.disposeBag)
        
        viewModel.canSeek.drive(progressSlider.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canFollow.drive(starButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canTogglePlay.drive(playButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canForward.drive(nextButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canBackward.drive(previousButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.nextUpString.drive(nextUpLabel.rx.text)
            .disposed(by: rx.disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

extension CurrentTrackViewController {
    
    @IBAction func starTapped(_ sender: Any) {
        viewModel.follow()
    }
    
    @IBAction func sliderScrubbed(_ sender: Any) {
        viewModel.scrub(to: progressSlider.value)
    }
    
    @IBAction func playTapped(_ sender: Any) {
        viewModel.togglePlay()
    }
    
    @IBAction func nextTapped(_ sender: Any) {
        viewModel.forward()
    }
    
    @IBAction func previousTapped(_ sender: Any) {
        viewModel.backward()
    }
    
    @IBAction func likeTapped(_ sender: Any) {
        viewModel.like()
    }
    
    @IBAction func dislikeTapped(_ sender: Any) {
        viewModel.dislike()
    }
    
}

extension CurrentTrackViewController {
    
    @IBAction func videoTapped(_ sender: Any) {
        viewModel.presentVideo()
    }
    
    @IBAction func lyricsTapped(_ sender: Any) {
        viewModel.presentLyrics()
    }
    
    @IBAction func promoTapped(_ sender: Any) {
        viewModel.presentPromo()
    }
    
    @IBAction func nowPlayingTapped(_ sender: Any) {
        viewModel.presentPlaying()
    }
    
    @IBAction func nextUpTapped(_ sender: Any) {
        viewModel.presentPlaying()
    }
    
}
