import Foundation
import CoreData

final class NetworkService {
    
    static let shared = NetworkService()
    private init() {}
    
    func fetchDataFromServer(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let noDataError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(noDataError))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let todos = json["todos"] as? [[String: Any]] {
                    completion(.success(todos))
                } else {
                    let parsingError = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])
                    completion(.failure(parsingError))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func saveTodosToCoreData(todos: [[String: Any]], context: NSManagedObjectContext, completion: @escaping (Result<Void, Error>) -> Void) {
        context.perform {
            for todoDict in todos {
                let newItem = ToDoListItem(context: context)
                newItem.id = todoDict["id"] as? Int16 ?? 0
                newItem.todo = todoDict["todo"] as? String
                newItem.completed = todoDict["completed"] as? Bool ?? false
                newItem.userId = todoDict["userId"] as? Int16 ?? 0
                newItem.createdAt = Date()
                newItem.title = String("Задача № \(newItem.id)")
            }
            
            do {
                try context.save()
                DispatchQueue.main.async {
                    completion(.success(()))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
