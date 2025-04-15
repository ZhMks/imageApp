import UIKit
// MARK: - presenter protocol
protocol IMainScreePresenter: AnyObject {
    func pushDetailsScreen(model: MainScreenModel)
    func viewDidLoad(_ view: IMainScreenView)
    func returnNumberOfItems() -> Int
    func returnImageList() -> [MainScreenModel]
    func fetchMoreImages(page: Int)
    func fetchData()
    func searchPhoto(page: Int, query: String)
    func emptySearchList()
}
// MARK: - view protocol
protocol IMainScreenView: AnyObject {
    func showDetailScreen(_ controller: UIViewController)
    func updateData()
    func showErrorAlert(_ error: Error)
    func reloadItemsAt(indexPath: [IndexPath])
}
// MARK: - presenter
final class MainScreenPresenter: IMainScreePresenter {
    // MARK: - properties
    weak var view: IMainScreenView?
    private var modelList: [MainScreenModel] = []
    private var searchedList: [MainScreenModel] = []
    private let dataService: IDataService
    // MARK: - lifecycle
    init(dataService: IDataService) {
        self.dataService = dataService
    }
    // MARK: - funcs
    func viewDidLoad(_ view: IMainScreenView) {
        self.view = view
    }
    
    func pushDetailsScreen(model: MainScreenModel) {
        let coredataService = CoreDataModelService()
        let detailScreen = ModuleBuilder.createDetailedScreen(id: model.id, coreDataService: coredataService, dataService: dataService,isfromFavourite: false)
        self.view?.showDetailScreen(detailScreen)
    }
    
    func fetchData() {
        dataService.initialFetchData() { [weak self] result in
            switch result {
            case .success(let success):
                let nsLock = NSLock()
                nsLock.lock()
                self?.modelList = success
                nsLock.unlock()
                self?.view?.updateData()
            case .failure(let failure):
                self?.view?.showErrorAlert(failure)
            }
        }
    }
    
    func returnNumberOfItems() -> Int {
        if searchedList.isEmpty {
            return modelList.count
        } else {
            return searchedList.count
        }
    }
    
    func returnImageList() -> [MainScreenModel] {
        if searchedList.isEmpty {
            return modelList
        } else {
            return searchedList
        }
    }
    
    func fetchMoreImages(page: Int) {
        let oldCount = modelList.count 
        dataService.fetchMoreData(page: page) { [weak self] result in
            switch result {
            case .success(let success):
                let nsLock = NSLock()
                nsLock.lock()
                self?.modelList.append(contentsOf: success)
                nsLock.unlock()
                guard let newCount = self?.modelList.count else { return }
                var newIndexPaths = [IndexPath]()
                for index in oldCount..<newCount {
                    newIndexPaths.append(IndexPath(item: index, section: 0))
                }
                self?.view?.reloadItemsAt(indexPath: newIndexPaths)
            case .failure(let failure):
                self?.view?.showErrorAlert(failure)
            }
        }
    }
    
    func searchPhoto(page: Int, query: String) {
        let oldCount = searchedList.count
        let nsLock = NSLock()
        dataService.searchPhoto(page: page, query: query) { [weak self] result in
            switch result {
            case .success(let success):
                guard let searchlist = self?.searchedList else { return }
                self?.modelList = []
                if searchlist.isEmpty {
                    nsLock.lock()
                    self?.searchedList = success
                    nsLock.unlock()
                    self?.view?.updateData()
                } else {
                    if page != 1 {
                        nsLock.lock()
                        self?.searchedList.append(contentsOf: success)
                        nsLock.unlock()
                        guard let newCount = self?.searchedList.count else { return }
                        var newIndexPaths = [IndexPath]()
                        for index in oldCount..<newCount {
                            newIndexPaths.append(IndexPath(item: index, section: 0))
                        }
                        self?.view?.reloadItemsAt(indexPath: newIndexPaths)
                    } else {
                        nsLock.lock()
                        self?.searchedList = success
                        nsLock.unlock()
                        self?.view?.updateData()
                    }
                }
            case .failure(let failure):
                self?.view?.showErrorAlert(failure)
            }
        }
    }
    
    func emptySearchList() {
        searchedList = []
    }
}
