//
//  SignUpRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol SignUpRouter: FlowRouter {
}

final class DefaultSignUpRouter:  SignUpRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case contriesSelectableList
        case regionsSelectableList
        case citiesSelectableList
        case hobbiesSelectableList
        case howHearSelectableList

        var identifier: String {
            switch self {
            case .contriesSelectableList: return "ContriesSelectableListSegueIdentifier"
            case .regionsSelectableList: return "RegionsSelectableListSegueIdentifier"
            case .citiesSelectableList: return "CitiesSelectableListSegueIdentifier"
            case .hobbiesSelectableList: return "HobbiesSelectableListSegueIdentifier"
            case .howHearSelectableList:return "HowHearSelectableListSegueIdentifier"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "ContriesSelectableListSegueIdentifier": return .contriesSelectableList
            case "RegionsSelectableListSegueIdentifier": return .regionsSelectableList
            case "CitiesSelectableListSegueIdentifier": return .citiesSelectableList
            case "HobbiesSelectableListSegueIdentifier": return .hobbiesSelectableList
            case "HowHearSelectableListSegueIdentifier":  return .howHearSelectableList
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: SignUpViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        case .contriesSelectableList:
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for contriesSelectableList") }
            guard let signUpViewModel = self.viewModel else { return }

            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let countriesSelectableListControllerViewModel = ContriesSelectableListControllerViewModel(router: selectableListRouter, dataSource: signUpViewModel, selectedItem: signUpViewModel.selectedCountry) { [weak signUpViewModel] (country) in
                signUpViewModel?.set(country: country)
            }

            selectableListRouter.start(controller: selectableListViewController, viewModel: countriesSelectableListControllerViewModel)

        case .regionsSelectableList:
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for regionsSelectableList") }
            guard let signUpViewModel = self.viewModel else { return }

            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let regionsSelectableListControllerViewModel = RegionsSelectableListControllerViewModel(router: selectableListRouter, dataSource: signUpViewModel, selectedItem: signUpViewModel.selectedRegion) { [weak signUpViewModel] (region) in
                signUpViewModel?.set(region: region)
            }

            selectableListRouter.start(controller: selectableListViewController, viewModel: regionsSelectableListControllerViewModel)

        case .citiesSelectableList:
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for regionsSelectableList") }
            guard let signUpViewModel = self.viewModel else { return }

            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let citiesSelectableListControllerViewModel = CitiesSelectableListControllerViewModel(router: selectableListRouter, dataSource: signUpViewModel, selectedItem: signUpViewModel.selectedCity) { [weak signUpViewModel] (city) in
                signUpViewModel?.set(city: city)
            }

            selectableListRouter.start(controller: selectableListViewController, viewModel: citiesSelectableListControllerViewModel)

        case .hobbiesSelectableList:
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for hobbiesSelectableList") }
            guard let signUpViewModel = self.viewModel else { return }

            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let hobbiesSelectableListControllerViewModel = HobbiesSelectableListControllerViewModel(router: selectableListRouter, dataSource: signUpViewModel, selectedItems: signUpViewModel.selectedHobbies) { [weak signUpViewModel] (hobbies) in
                signUpViewModel?.set(hobbies: hobbies)
            }

            selectableListRouter.start(controller: selectableListViewController, viewModel: hobbiesSelectableListControllerViewModel)

        case .howHearSelectableList:
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for regionsSelectableList") }
            guard let signUpViewModel = self.viewModel else { return }

            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let howHearSelectableListControllerViewModel = HowHearSelectableListControllerViewModel(router: selectableListRouter, dataSource: signUpViewModel, selectedItem: signUpViewModel.selectedHowHear) { [weak signUpViewModel] (howHear) in
                signUpViewModel?.set(howHear: howHear)
            }

            selectableListRouter.start(controller: selectableListViewController, viewModel: howHearSelectableListControllerViewModel)
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: SignUpViewController) {
        sourceController = controller
        let vm = SignUpControllerViewModel(router: self, restApiService: self.dependencies.restApiService)
        controller.configure(viewModel: vm, router: self)
        self.viewModel = vm
    }
}
