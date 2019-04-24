//
//  ContinueFacebookRegistrationViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import Alamofire

import RxSwift
import RxCocoa

extension ContinueFacebookRegistrationViewModel {
    
    var extraTicksHidden: Driver<Bool> {
        return country.asDriver()
            .map { $0?.code == "US" }
    }
    
}

struct ContinueFacebookRegistrationViewModel : MVVM_ViewModel {
    
    /** Reference dependent viewModels, managers, stores, tracking variables...
     
     fileprivate let privateDependency = Dependency()
     
     fileprivate let privateTextVar = BehaviourRelay<String?>(nil)
     
     */
    
    private let facebookToken: String
    let country = BehaviorRelay<Country?>(value: nil)
    
    init(router: ContinueFacebookRegistrationRouter, facebookToken: String) {
        self.router = router
        
        self.facebookToken = facebookToken
        
        ConfigRequest.countries.rx.response(type: [Country].self)
            .map { x in
                return x.first(where: { $0.code == "US" })
            }
            .asObservable()
            .bind(to: country)
            .disposed(by: bag)
        /**
         
         Proceed with initialization here
         
         */
        
        /////progress indicator
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
    }
    
    let router: ContinueFacebookRegistrationRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension ContinueFacebookRegistrationViewModel {
    
    func createAccount(birthday: Date, country: Country) {
        
        UserRequest.externalRegister(provider: .init( rout: .facebook,
                                                  accessToken: facebookToken,
                                                  birthdate: birthday,
                                                  howHear: 1,
                                                  country: country))
            .rx.response(type: FanLoginResponse.self)
            .silentCatch(handler: router.owner)
            .trackView(viewIndicator: indicator)
            .subscribe(onNext: { (resp) in
                
                Dispatcher.dispatch(action: SetNewUser(user: resp.user))
                
            })
            .disposed(by: bag)
        
    }
    
    func presentCountrySelection() {
        
        let vc = R.storyboard.selectableList.selectableListViewControllerIdentifer()!
        
        ///TODO: drop stupid datasource here
        let router = DefaultSelectableListRouter(dependencies: RouterDependencies.get)
        
        class DataSource: CountriesDataSource {
            
            var countries: [Country] = []
            
            func reloadCountries(completion: @escaping (Result<[Country]>) -> Void) {
                let _ =
                ConfigRequest.countries.rx.response(type: [Country].self)
                    .subscribe(onSuccess: { [weak self] (countries) in
                        self?.countries = countries
                        completion(.success(countries))
                    })
            }
            
        }
        
        let viewModel = ContriesSelectableListControllerViewModel(router: router,
                                                                  dataSource: DataSource(),
                                                                  selectedItem: nil,
                                                                  itemSelectionCallback: { [weak x = country] country in
                                                   x?.accept(country)
        })

        router.start(controller: vc, viewModel: viewModel)
        
        self.router.owner.navigationController?.pushViewController(vc, animated: true)
        
    }
    
}
