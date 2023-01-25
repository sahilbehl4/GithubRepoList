//
//  ViewController.swift
//  RxGithubRepoSearch
//
//  Created by Sahil Behl on 1/22/23.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var textField: UITextField!

    let viewModel = SearchViewModel()
    private let disposeBag = DisposeBag()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let searchText: Observable<String> = textField.rx.text.map { $0 ?? "" }
        let outputs = viewModel.transform(inputs: SearchViewModel.InputType(searchQueries: searchText))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        outputs.isLoading
            .bind(to: loadingView.rx.isAnimating)
            .disposed(by: disposeBag)

        outputs.isLoading
            .map { !$0 }
            .bind(to: loadingView.rx.isHidden)
            .disposed(by: disposeBag)

        outputs
            .repos
            .bind(to: tableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { _, repo, cell in
                var configuration = cell.defaultContentConfiguration()
                configuration.text = repo.name

                cell.contentConfiguration = configuration
            }
            .disposed(by: disposeBag)

        outputs.error.map { error in
            UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        }.do { alert in
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }.subscribe { alert in
            self.present(alert, animated: true, completion: nil)
        }.disposed(by: disposeBag)

    }
}

