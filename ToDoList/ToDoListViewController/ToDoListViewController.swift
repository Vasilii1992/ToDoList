import UIKit
import CoreData

protocol ToDoListViewProtocol: AnyObject {
    func showLoading()
    func hideLoading()
    func showError(title: String, message: String)
    func updateTodoList(_ todos: [ToDoListItem])
    func showEditDialog(for item: ToDoListItem, at index: Int)
}

final class ToDoListViewController: UIViewController, ToDoListViewProtocol {
    
    private var presenter: ToDoListPresenterProtocol!
    private var models = [ToDoListItem]()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        presenter = ToDoListPresenter(view: self, context: context)
        setupViews()
        presenter.viewDidLoad()
    }
    
    private func setupViews() {
        view.backgroundColor = .white
        navigationItem.title = "Заметки"
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
                                                message: "Напишите новую заметку",
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
                self?.showError(title: "Ошибка", message: "Обе строки должны быть заполнены.")
                self?.hideLoading()
                return
            }
            self?.presenter.didTapAdd(title: noteTitle, note: noteContent)
        }
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { [weak self] _ in
            self?.hideLoading()
        }
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - ToDoListViewProtocol Methods
    
    func showLoading() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func hideLoading() {
        activityIndicator.stopAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
    }
    
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func updateTodoList(_ todos: [ToDoListItem]) {
        self.models = todos
        tableView.reloadData()
    }
    
    func showEditDialog(for item: ToDoListItem, at index: Int) {
        showLoading()
        
        let alertController = UIAlertController(title: "Изменить Заметку", message: nil, preferredStyle: .alert)
        
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
            self?.presenter.updateItem(at: index, with: noteTitle, and: noteContent)
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

// MARK: - UITableViewDataSource

extension ToDoListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ToDoCell.identifire, for: indexPath) as? ToDoCell,
              let noteText = model.todo,
              let date = model.createdAt,
              let titleText = model.title else { return UITableViewCell() }
        
        cell.configure(titleText: titleText, noteText: noteText, date: date, isCompleted: model.completed)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ToDoListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectRow(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] action, view, completionHandler in
            self?.presenter.didSwipeToEdit(at: indexPath.row)
            completionHandler(true)
        }
        editAction.backgroundColor = .systemBlue
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] action, view, completionHandler in
            self?.presenter.didSwipeToDelete(at: indexPath.row)
            completionHandler(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        return configuration
    }
}
