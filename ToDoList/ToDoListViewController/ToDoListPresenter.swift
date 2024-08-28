import Foundation
import CoreData

protocol ToDoListPresenterProtocol: AnyObject {
    func viewDidLoad()
    func didTapAdd(title: String, note: String)
    func didSelectRow(at index: Int)
    func didSwipeToDelete(at index: Int)
    func didSwipeToEdit(at index: Int)
    func updateItem(at index: Int, with newTitle: String, and newTodo: String)
}

final class ToDoListPresenter: ToDoListPresenterProtocol {
    
    private weak var view: ToDoListViewProtocol?
    private var context: NSManagedObjectContext
    private var models = [ToDoListItem]()
    
    init(view: ToDoListViewProtocol, context: NSManagedObjectContext) {
        self.view = view
        self.context = context
    }
    
    func viewDidLoad() {
        let isDataDownloaded = UserDefaults.standard.bool(forKey: "isDataDownloaded")
        if !isDataDownloaded {
            fetchDataFromServer()
        } else {
            getAllItems()
        }
    }
    
    func didTapAdd(title: String, note: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.createItem(name: title, note: note)
            DispatchQueue.main.async {
                self?.view?.hideLoading()
            }
        }
    }
    
    func didSelectRow(at index: Int) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.models[index].completed.toggle()
            self?.saveContext()
        }
    }
    
    func didSwipeToDelete(at index: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.deleteItem(item: self.models[index])
        }
    }
    
    func didSwipeToEdit(at index: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let item = self.models[index]
            self.view?.showEditDialog(for: item, at: index)
        }
    }
    
    private func fetchDataFromServer() {
        view?.showLoading()
        NetworkService.shared.fetchDataFromServer { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                self?.view?.hideLoading()
                switch result {
                case .success(let todos):
                    DispatchQueue.global(qos: .background).async { [weak self] in
                        NetworkService.shared.saveTodosToCoreData(todos: todos, context: self?.context ?? NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)) { saveResult in
                            DispatchQueue.main.async {
                                switch saveResult {
                                case .success:
                                    UserDefaults.standard.set(true, forKey: "isDataDownloaded")
                                    self?.getAllItems()
                                case .failure(let error):
                                    self?.view?.showError(title: "Error", message: error.localizedDescription)
                                }
                            }
                        }
                    }
                case .failure(let error):
                    self?.view?.showError(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func getAllItems() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fetchRequest: NSFetchRequest<ToDoListItem> = ToDoListItem.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            do {
                self?.models = try self?.context.fetch(fetchRequest) ?? []
                DispatchQueue.main.async {
                    self?.view?.updateTodoList(self?.models ?? [])
                }
            } catch {
                DispatchQueue.main.async {
                    self?.view?.showError(title: "Error", message: "Failed to fetch items from Core Data")
                }
            }
        }
    }
    
    private func createItem(name: String, note: String) {
        let newItem = ToDoListItem(context: context)
        newItem.todo = note
        newItem.title = name
        newItem.createdAt = Date()
        models.insert(newItem, at: 0)
        saveContext()
    }
    
    private func deleteItem(item: ToDoListItem) {
        context.delete(item)
        saveContext()
    }
    
    private func saveContext() {
        do {
            try context.save()
            getAllItems()
        } catch {
            DispatchQueue.main.async {
                self.view?.showError(title: "Error", message: "Failed to save item")
            }
        }
    }
    
    func updateItem(at index: Int, with newTitle: String, and newTodo: String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let item = self?.models[index]
            item?.title = newTitle
            item?.todo = newTodo
            self?.saveContext()
        }
    }
}
