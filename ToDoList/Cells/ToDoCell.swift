import UIKit

final class ToDoCell: UITableViewCell {
    
    static let identifire = "ToDoCell"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        
        return label
    }()
    
    private let noteLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray2
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        
        return label
    }()
    
    let noteImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupViews() {
        addSubview(noteImageView)
        addSubview(titleLabel)
        addSubview(noteLabel)
        addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            noteImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            noteImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: noteImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            noteLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            noteLabel.leadingAnchor.constraint(equalTo: noteImageView.trailingAnchor, constant: 16),
            noteLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            
        ])
    }
    
    func configure(titleText: String, noteText: String, date: Date, isCompleted: Bool) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "d MMMM yyyy"
        titleLabel.text = titleText
        noteLabel.text = noteText
        dateLabel.text = dateFormatter.string(from: date)
        noteImageView.image = UIImage(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
    }
}
