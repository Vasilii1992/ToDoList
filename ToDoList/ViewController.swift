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
        guard let url = URL(string: "https://dummyjson.com/todos") else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "No error")")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let todos = json["todos"] as? [[String: Any]] {
                    print("Fetched data: \(todos)")  // Debug: Print fetched data
                    self?.saveTodosToCoreData(todos: todos)
                    
                    UserDefaults.standard.set(true, forKey: "isDataDownloaded")
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }
        task.resume()
    }


    func saveTodosToCoreData(todos: [[String: Any]]) {
        for todoDict in todos {
            let newItem = ToDoListItem(context: context)
            newItem.id = todoDict["id"] as? Int16 ?? 0
            newItem.todo = todoDict["todo"] as? String
            newItem.completed = todoDict["completed"] as? Bool ?? false
            newItem.userId = todoDict["userId"] as? Int16 ?? 0
            newItem.createdAt = Date()
        }
        saveContext()
        getAllItems()
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
        let alert = UIAlertController(title: "New Item",
                                      message: "Enter new item",
                                      preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Submit", style: .cancel, handler: { [weak self] _ in
            guard let field = alert.textFields?.first,let text = field.text, !text.isEmpty, let self = self else { return }
            self.createItem(name: text)
        }))
        
        
        present(alert, animated: true)
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


    
    func createItem(name: String) {
        let newItem = ToDoListItem(context: context)
        newItem.todo = name
        newItem.createdAt = Date()
        models.insert(newItem, at: 0)
        saveContext()
    }

    
    func deleteItem(item: ToDoListItem) {
        context.delete(item)
        saveContext()
    }
    
    func updateItem(item: ToDoListItem, newName: String) {
        item.todo = newName
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
        let item = models[index]
       
                   let alert = UIAlertController(title: "Elit Item",
                                                 message: "Edit your item",
                                                 preferredStyle: .alert)
                   alert.addTextField()
        alert.textFields?.first?.text = item.todo
                   alert.addAction(UIAlertAction(title: "Save", style: .cancel, handler: { [weak self] _ in
                       guard let field = alert.textFields?.first,let newName = field.text, !newName.isEmpty, let self = self else { return }
                       self.updateItem(item: item, newName: newName)
                   }))
       
                   self.present(alert, animated: true)
    }

}
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = models[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ToDoCell.identifire, for: indexPath) as? ToDoCell, let name = model.todo, let date = model.createdAt else { return UITableViewCell() }
       
        cell.configure(name: name, date: date, isCompleted: model.completed)

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
