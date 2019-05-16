//
//  ArtistsFollowedViewModelTests.swift
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

class ArtistsFollowedViewModelTests: XCTestCase {
    
    var viewModel: ArtistsFollowedViewModel?
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [],
                                      ws: FakeWebSocketService(),
                                      network: FakeNetwork()))
        FakeRequest.Artist.registerMockRequestArtistFollowing()
        Dispatcher.state.accept(AppState.fake())
        
        
        let vc = UIViewController()
        viewModel = ArtistsFollowedViewModel(router: ArtistsFollowedRouter(owner: vc))
        
    }
    
    func testQueryWithAllItems() {
        
        var searchResult = [AnimatableSectionModel<String, Artist>]()
        
        viewModel!.dataSource
            .filter({ (selectionModel) -> Bool in
                return selectionModel.first!.items.count > 0
            })
            .drive(onNext: { (sectionModel) in
                searchResult = sectionModel
            })
            .disposed(by: rx.disposeBag)
        
        viewModel!.queryChanges("ivan")
        
        expect(searchResult.first?.items.count).toEventually(equal(5))
    }
    
    func testQueryWithOneItem() {
        
        var searchResult = [AnimatableSectionModel<String, Artist>]()
        
        viewModel!.dataSource
            .filter({ (selectionModel) -> Bool in
                return selectionModel.first!.items.count > 0
            })
            .drive(onNext: { (sectionModel) in
                searchResult = sectionModel
            })
            .disposed(by: rx.disposeBag)
        
        viewModel!.queryChanges("ivan PetRov")
        
        expect(searchResult.first?.items.count).toEventually(equal(1))
    }
    
    func testQueryWithTwoItems() {
        
        var searchResult = [AnimatableSectionModel<String, Artist>]()
        
        viewModel!.dataSource
            .filter({ (selectionModel) -> Bool in
                return selectionModel.first!.items.count > 0
            })
            .drive(onNext: { (sectionModel) in
                searchResult = sectionModel
            })
            .disposed(by: rx.disposeBag)
        
        viewModel!.queryChanges("ivan S")
        
        expect(searchResult.first?.items.count).toEventually(equal(2))
    }
    
    func testQueryWithNoResult() {
        
        var searchResult = [AnimatableSectionModel<String, Artist>]()
        
        viewModel!.dataSource
            .skip(1)
            .drive(onNext: { (sectionModel) in
                searchResult = sectionModel
            })
            .disposed(by: rx.disposeBag)
        
        viewModel!.queryChanges("dmitriy")
        
        expect(searchResult.first?.items.count).toEventually(equal(0))
    }
}

