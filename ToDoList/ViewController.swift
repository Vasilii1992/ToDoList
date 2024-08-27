//
//  ViewController.swift
//  ToDoList
//
//  Created by Василий Тихонов on 26.08.2024.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    let tableView: UITableView = {
       let tableView = UITableView()
        tableView.register(ToDoCell.self, forCellReuseIdentifier: ToDoCell.identifire)
        return tableView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()
    
    private var models = [ToDoListItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        let isDataDownloaded = UserDefaults.standard.bool(forKey: "isDataDownloaded")
        
        if !isDataDownloaded {
            fetchDataFromServer()
        } else {
            getAllItems()
        }
    }

    func fetchDataFromServer() {
           NetworkService.shared.fetchDataFromServer { [weak self] result in
               switch result {
               case .success(let todos):
                   print("Fetched data: \(todos)")
                   NetworkService.shared.saveTodosToCoreData(todos: todos, context: self?.context ?? NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)) { saveResult in
                       switch saveResult {
                       case .success:
                           UserDefaults.standard.set(true, forKey: "isDataDownloaded")
                           self?.getAllItems()
                       case .failure(let error):
                           print("Failed to save data to Core Data: \(error.localizedDescription)")
                       }
                   }
               case .failure(let error):
                   print("Failed to fetch data: \(error.localizedDescription)")
               }
           }
       }


    private func setupViews() {
        view.backgroundColor = .white
        navigationItem.title = "To Do List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(didTapAdd))

        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    
    @objc private func didTapAdd() {
        
        showLoading()
        
        let alertController = UIAlertController(title: "Новая Заметка",
                                                message: "Запиши свою заметку",
                                                preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Заголовок"
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Заметка..."
        }
        
        let addAction = UIAlertAction(title: "Добавить", style: .default) { [weak self] _ in
            guard let textFields = alertController.textFields,
                  let titleField = textFields.first, let noteTitle = titleField.text, !noteTitle.isEmpty,
                  let contentField = textFields.last, let noteContent = contentField.text, !noteContent.isEmpty else {
                  self?.showError(title: "Ошибка", message: "Оба поля не могут быть пустыми.")
                return
            }
            self?.createItem(name: noteTitle, note: noteContent)
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.hideLoading()
        }
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
        
    }
    
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showLoading() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func hideLoading() {
        activityIndicator.stopAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
    }
    
    
    // Core Data

    func getAllItems() {
        let fetchRequest: NSFetchRequest<ToDoListItem> = ToDoListItem.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            models = try context.fetch(fetchRequest)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Failed to fetch items from Core Data: \(error)")
        }
    }

    func createItem(name: String, note: String) {
        let newItem = ToDoListItem(context: context)
        newItem.todo = note
        newItem.title = name
        newItem.createdAt = Date()
        models.insert(newItem, at: 0)
        hideLoading()
        saveContext()
    }
    
    func deleteItem(item: ToDoListItem) {
        context.delete(item)
        saveContext()
    }
    
    func updateItem(item: ToDoListItem, newTodo: String, newTitle: String) {
        item.todo = newTodo
        item.title = newTitle
         saveContext()
    }
    
    private func saveContext() {
        do {
            try context.save()
            getAllItems()
        } catch {
            // error
        }
    }
    
    func editNote(at index: Int) {
        
        showLoading()
        
        let item = models[index]
       
                   let alertController = UIAlertController(title: "Редактировать Заметку",
                                                 message: nil,
                                                 preferredStyle: .alert)
        
        
        alertController.addTextField { textField in
            textField.placeholder = "Заголовок"
            textField.text = item.title
        }
        
        alertController.addTextField { textField in
            textField.placeholder = "Заметка..."
            textField.text = item.todo
        }
        
        let saveAction = UIAlertAction(title: "Сохранить", style: .default) { [weak self] _ in
            guard let textFields = alertController.textFields,
                  let titleField = textFields.first, let noteTitle = titleField.text, !noteTitle.isEmpty,
                  let contentField = textFields.last, let noteContent = contentField.text, !noteContent.isEmpty else {
                self?.showError(title: "Ошибка", message: "Заголовок и заметка не могут быть пустыми")
                self?.hideLoading()
                return
            }
            self?.updateItem(item: item, newTodo: noteContent, newTitle: noteTitle)
            self?.hideLoading()
        }
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.hideLoading()
        }
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
}
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = models[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ToDoCell.identifire, for: indexPath) as? ToDoCell, let noteText = model.todo, let date = model.createdAt, let titleText = model.title else { return UITableViewCell() }
               
        cell.configure(titleText: titleText, noteText: noteText, date: date, isCompleted: model.completed)

        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = models[indexPath.row]
        item.completed.toggle()
        saveContext()
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = models[indexPath.row]
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] action, view, completionHandler in
            self?.editNote(at: indexPath.row)
            completionHandler(true)
        }
        editAction.backgroundColor = .systemBlue
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] action, view, completionHandler in
            
            self?.deleteItem(item: item)
            tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .automatic)

            completionHandler(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        return configuration
    }
}
