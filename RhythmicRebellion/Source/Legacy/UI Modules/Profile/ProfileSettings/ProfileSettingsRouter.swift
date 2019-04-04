//
//  ProfileSettingsRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/12/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ProfileSettingsRouter: FlowRouter {
    func showContriesSelectableList(dataSource: CountriesDataSource, selectedItem: Country?, selectionCallback: @escaping (Country) -> Void)
    func showRegionsSelectableList(dataSource: RegionsDataSource, selectedItem: Region?, selectionCallback: @escaping (Region) -> Void)
    func showCitiesSelectableList(dataSource: CitiesDataSource, selectedItem: City?, selectionCallback: @escaping (City) -> Void)
    func showHobbiesSelectableList(dataSource: HobbiesDataSource, selectedItems: [Hobby]?, additionalItems: [Hobby]?, selectionCallback: @escaping ([Hobby]) -> Void)
    func showGenresSelectableList(dataSource: GenresDataSource, selectedItems: [Genre]?, additionalItems: [Genre]?, selectionCallback: @escaping ([Genre]) -> Void)
    func showLanguagesSelectableList(dataSource: LanguagesDataSource, selectedItems: Language?, selectionCallback: @escaping (Language) -> Void)

    func navigateBack()
}

final class DefaultProfileSettingsRouter:  ProfileSettingsRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case contriesSelectableList = "ContriesSelectableListSegueIdentifier"
        case regionsSelectableList = "RegionsSelectableListSegueIdentifier"
        case citiesSelectableList = "CitiesSelectableListSegueIdentifier"
        case hobbiesSelectableList = "HobbiesSelectableListSegueIdentifier"
        case genresSelectableList = "GenresSelectableListSegueIdentifier"
        case languagesSelectableList = "LanguagesSelectableListSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showContriesSelectableList(dataSource: CountriesDataSource, selectedItem: Country?, selectionCallback: (Country) -> Void)
        case showRegionsSelectableList(dataSource: RegionsDataSource, selectedItem: Region?, selectionCallback: (Region) -> Void)
        case showCitiesSelectableList(dataSource: CitiesDataSource, selectedItem: City?, selectionCallback: (City) -> Void)
        case showHobbiesSelectableList(dataSource: HobbiesDataSource, selectedItems: [Hobby]?, additionalItems: [Hobby]?, selectionCallback: ([Hobby]) -> Void)
        case showGenresSelectableList(dataSource: GenresDataSource, selectedItems: [Genre]?, additionalItems: [Genre]?, selectionCallback: ([Genre]) -> Void)
        case showLanguagesSelectableList(dataSource: LanguagesDataSource, selectedItems: Language?, selectionCallback: (Language) -> Void)

        var identifier: SegueDestinationList {
            switch self {
            case .showContriesSelectableList: return SegueList.contriesSelectableList
            case .showRegionsSelectableList: return SegueList.regionsSelectableList
            case .showCitiesSelectableList: return SegueList.citiesSelectableList
            case .showHobbiesSelectableList: return SegueList.hobbiesSelectableList
            case .showGenresSelectableList: return SegueList.genresSelectableList
            case .showLanguagesSelectableList: return SegueList.languagesSelectableList
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: ProfileSettingsViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultProfileSettingsRouter.SegueActions, segue: UIStoryboardSegue) {

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

        case .showHobbiesSelectableList(let dataSource, let selectedItems, let additionalItems, let selectionCallback):
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for hobbiesSelectableList") }
            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let hobbiesSelectableListControllerViewModel = HobbiesSelectableListControllerViewModel(router: selectableListRouter,
                                                                                                    dataSource: dataSource,
                                                                                                    selectedItems: selectedItems,
                                                                                                    additionalItems: additionalItems,
                                                                                                    itemsSelectionCallback: selectionCallback)

            selectableListRouter.start(controller: selectableListViewController, viewModel: hobbiesSelectableListControllerViewModel)

        case .showGenresSelectableList(let dataSource, let selectedItems, let additionalItems, let selectionCallback):
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for GenresSelectableListSegueIdentifier") }
            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)

            let genresSelectableListControllerViewModel = GenresSelectableListControllerViewModel(router: selectableListRouter,
                                                                                                   dataSource: dataSource,
                                                                                                   selectedItems: selectedItems,
                                                                                                   additionalItems: additionalItems,
                                                                                                   itemsSelectionCallback: selectionCallback)

            selectableListRouter.start(controller: selectableListViewController, viewModel: genresSelectableListControllerViewModel)

        case .showLanguagesSelectableList(let dataSource, let selectedItem, let selectionCallback):
            guard let selectableListViewController = segue.destination as? SelectableListViewController else { fatalError("Incorrect controller for showLanguagesSelectableList") }
            let selectableListRouter = DefaultSelectableListRouter(dependencies: self.dependencies)
            let citiesSelectableListControllerViewModel = LanguagesSelectableListControllerViewModel(router: selectableListRouter,
                                                                                                  dataSource: dataSource,
                                                                                                  selectedItem: selectedItem,
                                                                                                  itemSelectionCallback: selectionCallback)

            selectableListRouter.start(controller: selectableListViewController, viewModel: citiesSelectableListControllerViewModel)

        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: ProfileSettingsViewController) {
        sourceController = controller
        let vm = ProfileSettingsControllerViewModel(router: self, application: self.dependencies.application)
        controller.configure(viewModel: vm, router: self)
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

    func showHobbiesSelectableList(dataSource: HobbiesDataSource, selectedItems: [Hobby]?, additionalItems: [Hobby]?, selectionCallback: @escaping ([Hobby]) -> Void) {
        self.perform(segue: .showHobbiesSelectableList(dataSource: dataSource,
                                                       selectedItems: selectedItems,
                                                       additionalItems: additionalItems,
                                                       selectionCallback: selectionCallback))
    }

    func showGenresSelectableList(dataSource: GenresDataSource, selectedItems: [Genre]?, additionalItems: [Genre]?, selectionCallback: @escaping ([Genre]) -> Void) {
        self.perform(segue: .showGenresSelectableList(dataSource: dataSource,
                                                      selectedItems: selectedItems,
                                                      additionalItems: additionalItems,
                                                      selectionCallback: selectionCallback))
    }

    func showLanguagesSelectableList(dataSource: LanguagesDataSource, selectedItems: Language?, selectionCallback: @escaping (Language) -> Void) {
        self.perform(segue: .showLanguagesSelectableList(dataSource: dataSource, selectedItems: selectedItems, selectionCallback: selectionCallback))
    }

    func navigateBack() {
        self.sourceController?.navigationController?.popViewController(animated: true)
    }
}
