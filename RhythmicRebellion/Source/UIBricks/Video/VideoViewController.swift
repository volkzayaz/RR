//
//  VideoViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/25/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import youtube_ios_player_helper

class VideoViewController: UIViewController, MVVM_View {
    
    var viewModel: VideoViewModel!
    
    @IBOutlet weak var videoView: YTPlayerView!
    @IBOutlet weak var videoView2: YTPlayerView!
    /**
     *  Connect any IBOutlets here
     *  @IBOutlet weak var label: UILabel!
     */
    @IBOutlet weak var noVideosLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.video1
            .drive(onNext: { [unowned self] (maybeURL) in
                self.videoView.isHidden = maybeURL == nil
                if let x = maybeURL {
                    let playerVars = [
                        "origin" : "http://www.youtube.com"
                    ]
                    self.videoView.load(withVideoId: x, playerVars: playerVars)
                }
            })
            .disposed(by: rx.disposeBag)

        viewModel.video1.map { $0 != nil }
            .drive(noVideosLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        viewModel.video2
            .drive(onNext: { [unowned self] (maybeURL) in
                self.videoView2.isHidden = maybeURL == nil
                if let x = maybeURL {
                    
                    let playerVars = [
                        "origin" : "http://www.youtube.com"
                    ]
                    self.videoView2.load(withVideoId: x, playerVars: playerVars)
                }
            })
            .disposed(by: rx.disposeBag)
        
    }
    
}

extension VideoViewController {
    
    /**
     *  Describe any IBActions here
     *
     
     @IBAction func performAction(_ sender: Any) {
     
     }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
     }
 
    */
    
}
