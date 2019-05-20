//
//  TrackListViewModelTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/16/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa
import RxSwift
import Differentiator

@testable import RhythmicRebellion

class TrackListViewModelTests: XCTestCase {
    
    var viewModel: ArtistsFollowedViewModel?
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        FakeRequest.Artist.registerMockRequestArtistFollowing()
        Dispatcher.state.accept(AppState.fake())
        
        let vc = UIViewController()
        viewModel = ArtistsFollowedViewModel(router: ArtistsFollowedRouter(owner: vc))
    }
    
    func queryChange(_ text: String,
                     skip:Int = 1,
                     result: @escaping ([AnimatableSectionModel<String, Artist>]) -> Void) {
        
        viewModel!.dataSource.skip(skip).drive(onNext: result).disposed(by: rx.disposeBag)
        viewModel!.queryChanges(text)
    }
    
    func testQueryWithAllItems() {
        queryChange("ivan") {
            expect($0.first!.items.count).toEventually(equal(5))
        }
    }
    
    func testQueryWithOneItem() {
        queryChange("ivan PetRov") {
            expect($0.first!.items.count).toEventually(equal(1))
        }
    }
    
    func testQueryWithTwoItems() {
        queryChange("ivan S") {
            expect($0.first!.items.count).toEventually(equal(2))
        }
    }
    
    func testQueryWithNoResult() {    
        queryChange("dmitriy", skip: 0) {
            expect($0.first!.items.count).toEventually(equal(0))
        }
    }
}

