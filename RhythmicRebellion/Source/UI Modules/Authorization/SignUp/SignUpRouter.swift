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
    func showContriesSelectableList(dataSource: CountriesDataSource, selectedItem: Country?, selectionCallback: @escaping (Country) -> Void)
    func showRegionsSelectableList(dataSource: RegionsDataSource, selectedItem: Region?, selectionCallback: @escaping (Region) -> Void)
    func showCitiesSelectableList(dataSource: CitiesDataSource, selectedItem: City?, selectionCallback: @escaping (City) -> Void)
    func showHobbiesSelectableList(dataSource: HobbiesDataSource, selectedItems: [Hobby]?, selectionCallback: @escaping ([Hobby]) -> Void)
    func showHowHearSelectableList(dataSource: HowHearListDataSource, selectedItem: HowHear?, selectionCallback: @escaping (HowHear) -> Void)
}

final class DefaultSignUpRouter:  SignUpRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case contriesSelectableList = "ContriesSelectableListSegueIdentifier"
        case regionsSelectableList = "RegionsSelectableListSegueIdentifier"
        case citiesSelectableList = "CitiesSelectableListSegueIdentifier"
        case hobbiesSelectableList = "HobbiesSelectableListSegueIdentifier"
        case howHearSelectableList = "HowHearSelectableListSegueIdentifier"

    }

    enum SegueActions: SegueDestinations {
        case showContriesSelectableList(dataSource: CountriesDataSource, selectedItem: Country?, selectionCallback: (Country) -> Void)
        case showRegionsSelectableList(dataSource: RegionsDataSource, selectedItem: Region?, selectionCallback: (Region) -> Void)
        case showCitiesSelectableList(dataSource: CitiesDataSource, selectedItem: City?, selectionCallback: (City) -> Void)
        case showHobbiesSelectableList(dataSource: HobbiesDataSource, selectedItems: [Hobby]?, selectionCallback: ([Hobby]) -> Void)
        case showHowHearSelectableList(dataSource: HowHearListDataSource, selectedItem: HowHear?, selectionCallback: (HowHear) -> Void)

        var identifier: SegueDestinationList {
            switch self {
            case .showContriesSelectableList: return SegueList.contriesSelectableList
            case .showRegionsSelectableList: return SegueList.regionsSelectableList
            case .showCitiesSelectableList: return SegueList.citiesSelectableList
            case .showHobbiesSelectableList: return SegueList.hobbiesSelectableList
            case .showHowHearSelectableList: return SegueList.howHearSelectableList
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: SignUpViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultSignUpRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {

        case .showContriesSelectableList(let dataSource, let selectedItem, let selectionCallback):
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for contriesSelectableList") }
            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)
            let countriesSelectableListControllerViewModel = ContriesSelectableListControllerViewModel(router: selectableListRouter,
                                                                                                       dataSource: dataSource,
                                                                                                       selectedItem: selectedItem,
                                                                                                       itemSelectionCallback: selectionCallback)

            selectableListRouter.start(controller: selectableListViewController, viewModel: countriesSelectableListControllerViewModel)

        case .showRegionsSelectableList(let dataSource, let selectedItem, let selectionCallback):
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for regionsSelectableList") }
            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)
            let regionsSelectableListControllerViewModel = RegionsSelectableListControllerViewModel(router: selectableListRouter,
                                                                                                    dataSource: dataSource,
                                                                                                    selectedItem: selectedItem,
                                                                                                    itemSelectionCallback: selectionCallback)

            selectableListRouter.start(controller: selectableListViewController, viewModel: regionsSelectableListControllerViewModel)

        case .showCitiesSelectableList(let dataSource, let selectedItem, let selectionCallback):
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for regionsSelectableList") }
            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)
            let citiesSelectableListControllerViewModel = CitiesSelectableListControllerViewModel(router: selectableListRouter,
                                                                                                  dataSource: dataSource,
                                                                                                  selectedItem: selectedItem,
                                                                                                  itemSelectionCallback: selectionCallback)

            selectableListRouter.start(controller: selectableListViewController, viewModel: citiesSelectableListControllerViewModel)

        case .showHobbiesSelectableList(let dataSource, let selectedItems, let selectionCallback):
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for hobbiesSelectableList") }
            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let hobbiesSelectableListControllerViewModel = HobbiesSelectableListControllerViewModel(router: selectableListRouter,
                                                                                                    dataSource: dataSource,
                                                                                                    selectedItems: selectedItems,
                                                                                                    itemsSelectionCallback: selectionCallback)

            selectableListRouter.start(controller: selectableListViewController, viewModel: hobbiesSelectableListControllerViewModel)

        case .showHowHearSelectableList(let dataSource, let selectedItem, let selectionCallback):
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for regionsSelectableList") }
            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let howHearSelectableListControllerViewModel = HowHearSelectableListControllerViewModel(router: selectableListRouter,
                                                                                                    dataSource: dataSource,
                                                                                                    selectedItem: selectedItem,
                                                                                                    itemSelectionCallback: selectionCallback)

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

    func showContriesSelectableList(dataSource: CountriesDataSource, selectedItem: Country?, selectionCallback: @escaping (Country) -> Void) {
        self.perform(segue: .showContriesSelectableList(dataSource: dataSource, selectedItem: selectedItem, selectionCallback: selectionCallback))
    }

    func showRegionsSelectableList(dataSource: RegionsDataSource, selectedItem: Region?, selectionCallback: @escaping (Region) -> Void) {
        self.perform(segue: .showRegionsSelectableList(dataSource: dataSource, selectedItem: selectedItem, selectionCallback: selectionCallback))
    }

    func showCitiesSelectableList(dataSource: CitiesDataSource, selectedItem: City?, selectionCallback: @escaping (City) -> Void) {
        self.perform(segue: .showCitiesSelectableList(dataSource: dataSource, selectedItem: selectedItem, selectionCallback: selectionCallback))
    }

    func showHobbiesSelectableList(dataSource: HobbiesDataSource, selectedItems: [Hobby]?, selectionCallback: @escaping ([Hobby]) -> Void) {
        self.perform(segue: .showHobbiesSelectableList(dataSource: dataSource, selectedItems: selectedItems, selectionCallback: selectionCallback))
    }

    func showHowHearSelectableList(dataSource: HowHearListDataSource, selectedItem: HowHear?, selectionCallback: @escaping (HowHear) -> Void) {
        self.perform(segue: .showHowHearSelectableList(dataSource: dataSource, selectedItem: selectedItem, selectionCallback: selectionCallback))
    }

}
