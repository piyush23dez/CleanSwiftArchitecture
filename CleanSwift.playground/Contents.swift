//: Playground - noun: a place where people can play

import UIKit


//MARK: Models
struct Feed {
    var title: String
    var author: String
    var publishedOn: String
}

struct FeedsFetchRequest {
    var email: String?
    var password: String?
}

struct FeedsFetchResponse {
    var feeds: [Feed]?
    var error: FeedsFetchError?
}

struct FeedsViewModel {
    var feeds: [Feed]?
    var error: String?
}

struct User {
    let email: String
    let password: String
}

//MARK: Error Handle
enum FeedsFetchError: Error {
    case cannotFetch(msg: String)
}



//MARK: Datasource Interface
protocol Datasource {
    associatedtype DataType = Feed
    func getFeeds(for user: User, completion: @escaping ([DataType]) -> ())
}

//MARK: Data Sources
class FeedService: Datasource {
    func getFeeds(for user: User, completion: @escaping ([Feed]) -> ()) {
        let feeds: [Feed] = []
        completion(feeds)
    }
}

class CloudStore: Datasource {
    func getFeeds(for user: User, completion: @escaping ([Feed]) -> ()) {
        let feeds: [Feed] = []
        completion(feeds)
    }
}

class CacheStore: Datasource {
    func getFeeds(for user: User, completion: @escaping ([Feed]) -> ()) {
        let feeds: [Feed] = []
        completion(feeds)
    }
}


//MARK: DataManager
struct DataManager<DataStoreType: Datasource> where DataStoreType.DataType == Feed {
    private let dataSource: DataStoreType
    
    init(dataSource: DataStoreType) {
        self.dataSource = dataSource
    }
    
    func fetchFeeds(for user: User, completion: @escaping ([Feed]) -> ()) {
        dataSource.getFeeds(for: user) { (feeds: [Feed]) in
            completion(feeds)
        }
    }
}

//MARK: Worker
class FeedsWorker {
    //let dataStore = CloudStore()
    //let dataStore = CacheStore()
    //let dataStore = FeedService()
    
    private let dataManager = DataManager(dataSource: FeedService())
    func fetchFeeds(for user: User, completion: @escaping ([Feed]) -> ()) {
        dataManager.fetchFeeds(for: user) { (feeds: [Feed]) in
            completion(feeds)
        }
    }
}


//MARK: Interactor Interface
protocol FeedsInteractorInput {
    func fetchFeeds(_ request: FeedsFetchRequest)
}

protocol FeedsInteractorOutput {
    func presentFeeds(_ response: FeedsFetchResponse)
}


//MARK: Interactor
class FeedsInteractor: FeedsInteractorInput {

    var output: FeedsInteractorOutput!
    var worker: FeedsWorker!
    
    func fetchFeeds(_ request: FeedsFetchRequest) {
        // NOTE: Create some Worker to do the work
        worker = FeedsWorker()
        
        let user = User(email: request.email!, password: request.password!)
        worker.fetchFeeds(for: user) { (feeds) in
            // NOTE: Pass the result to the Presenter
            let response = FeedsFetchResponse(feeds: feeds, error: nil)
            self.output.presentFeeds(response)
        }
    }
}

//MARK: Router
protocol FeedsRouterInput {
    func navigateToSomewhere()
}


class FeedsRouter: FeedsRouterInput {
    weak var viewController: FeedsViewController!
    
    // MARK: Navigation
    func navigateToSomewhere() {
        // NOTE: Teach the router how to navigate to another scene. Some examples follow:
        
        // 1. Trigger a storyboard segue
        // viewController.performSegueWithIdentifier("ShowSomewhereScene", sender: nil)
        
        // 2. Present another view controller programmatically
        // viewController.presentViewController(someWhereViewController, animated: true, completion: nil)
        
        // 3. Ask the navigation controller to push another view controller onto the stack
        // viewController.navigationController?.pushViewController(someWhereViewController, animated: true)
        
        // 4. Present a view controller from a different storyboard
        // let storyboard = UIStoryboard(name: "OtherThanMain", bundle: nil)
        // let someWhereViewController = storyboard.instantiateInitialViewController() as! SomeWhereViewController
        // viewController.navigationController?.pushViewController(someWhereViewController, animated: true)
    }
    
    // MARK: Communication
    func passDataToNextScene(_ segue: UIStoryboardSegue) {
        // NOTE: Teach the router which scenes it can communicate with
        
        if segue.identifier == "ShowSomewhereScene" {
            passDataToSomewhereScene(segue)
        }
    }
    
    func passDataToSomewhereScene(_ segue: UIStoryboardSegue) {
        // NOTE: Teach the router how to pass data to the next scene
        // let someWhereViewController = segue.destinationViewController as! SomeWhereViewController
        // someWhereViewController.output.name = viewController.output.name
    }
}


//MARK: Presenter Interface
protocol FeedsPresenterInput {
    func presentFeeds(_ response: FeedsFetchResponse)
}

protocol FeedsPresenterOutput: class {
    func displayFeeds(_ viewModel: FeedsViewModel)
    func displayFeedsFetchError(_ viewModel: FeedsViewModel)
}

//MARK: Presenter
class FeedsPresenter: FeedsPresenterInput {
    weak var output: FeedsPresenterOutput!

    func presentFeeds(_ response: FeedsFetchResponse) {
        processPresentation(for: response.feeds!)
    }
    
    private func processPresentation(for feeds: [Feed]) {
        //preform data formatting if needed
        let viewModel = FeedsViewModel(feeds: feeds, error: nil)
        output.displayFeeds(viewModel)
    }
}

//MARK: View Interface
protocol FeedsViewControllerInput {
    func displayFeeds(_ viewModel: FeedsViewModel)
    func displayFeedsFetchError(_ viewModel: FeedsViewModel)
}

protocol FeedsViewControllerOutput {
    func fetchFeeds(_ request: FeedsFetchRequest)
}


//MARK: View
class FeedsViewController: UITableViewController {
    
    var output: FeedsViewControllerOutput!
    var router: FeedsRouter!
    var feeds: [Feed] = []

    // MARK: Object lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        FeedsConfigurator.instance.configure(viewController: self)
    }
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchFeedsOnLoad()
    }
    
    // MARK: Fetch Feeds
    fileprivate func fetchFeedsOnLoad() {
        // NOTE: Ask the Interactor to do some work
        let request = FeedsFetchRequest(email: "wwdc@apple.com", password: "2017")
        output.fetchFeeds(request)
    }
}


//MARK: ViewController Interface Conformance
extension FeedsViewController: FeedsViewControllerInput {
    
    func displayFeeds(_ viewModel: FeedsViewModel) {
        if let feeds = viewModel.feeds {
            refresh(feeds: feeds)
        }
    }
    
    func displayFeedsFetchError(_ viewModel: FeedsViewModel) {
        if let error = viewModel.error {
            print(error)
        }
    }
    
    func refresh(feeds: [Feed]) {
        self.feeds = feeds
        tableView.reloadData()
    }
}

// MARK: Connect View, Interactor, and Presenter
extension FeedsViewController: FeedsPresenterOutput {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.router.passDataToNextScene(segue)
    }
}

extension FeedsInteractor: FeedsViewControllerOutput {}
extension FeedsPresenter: FeedsInteractorOutput {}

class FeedsConfigurator {
    
    // MARK: Object lifecycle
    static let instance = FeedsConfigurator()
    private init() {}
    
    // MARK: Configuration
    func configure(viewController: FeedsViewController) {
        let router = FeedsRouter()
        router.viewController = viewController
        
        let presenter = FeedsPresenter()
        presenter.output = viewController
        
        let interactor = FeedsInteractor()
        interactor.output = presenter
        
        viewController.output = interactor
        viewController.router = router
    }
}




