//
//  DiaryViewController.swift
//  Segno
//
//  Created by 이예준 on 2022/11/10.
//

import UIKit

import RxCocoa
import RxSwift
import SnapKit

protocol DiaryCollectionViewDelegate: AnyObject {
    func diaryCellSelected(id: String)
    func diaryAppendButtonTapped()
}

final class DiaryCollectionViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, DiaryListItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DiaryListItem>
    
    enum Section: CaseIterable {
        case main
    }
    
    private enum Metric {
        static let buttonFontSize: CGFloat = 80
        static let buttonLabelOffset: CGFloat = 7
        static let buttonOffset: CGFloat = -20
        static let buttonRadius: CGFloat = 40
        static let buttonText: String = "+"
        static let buttonWidthAndHeight: CGFloat = 80
        static let inset: CGFloat = 20
        static let navigationTitleSize: CGFloat = 20
        static let navigationBackButtonTitleSize: CGFloat = 16
    }
    
    let disposeBag = DisposeBag()
    private let viewModel: DiaryCollectionViewModel
    private var dataSource: DataSource?
    private var diaryCells: [DiaryListItem] = []
    weak var delegate: DiaryCollectionViewDelegate?
    
    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "제목으로 검색"
        bar.searchTextField.font = .appFont(.shiningStar, size: 20)
        bar.setImage(UIImage(named: "search_back"), for: .search, state: .normal)
        bar.setImage(UIImage(named: "search_cancel"), for: .clear, state: .normal)
        return bar
    }()
    
    private lazy var refreshControl = UIRefreshControl()
    
    private lazy var diaryCollectionView: UICollectionView = {
        let layout = makeCollectionViewLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .appColor(.color3)
        return collectionView
    }()
    
    private lazy var appendButton = UIButton()
    
    private lazy var appendButtonLabel: UILabel = {
        let label = UILabel()
        label.font = .appFont(.surroundAir, size: Metric.buttonFontSize)
        label.text = Metric.buttonText
        label.textColor = .appColor(.white)
        return label
    }()
    
    private lazy var backBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: "리스트", style: .plain, target: self, action: nil)
        item.tintColor = UIColor.appColor(.color4)
        item.setTitleTextAttributes([
            NSAttributedString.Key.font: UIFont.appFont(.surroundAir, size: Metric.navigationBackButtonTitleSize)], for: .normal)
        return item
    }()
    
    init() {
        self.viewModel = DiaryCollectionViewModel()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupLayout()
        setupRx()
        setRecognizer()
        
        dataSource = makeDataSource()
        bindDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getDatasource()
        updateSnapshot(with: searchBar.text)
    }
    
    private func setupView() {
        view.backgroundColor = .appColor(.background)
        
        title = "일기 리스트"
        navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.font: UIFont.appFont(.surround, size: Metric.navigationTitleSize),
            NSAttributedString.Key.foregroundColor: UIColor.appColor(.color4) ?? .red
        ]
        
        navigationItem.backBarButtonItem = backBarButtonItem
        
        searchBar.delegate = self
        diaryCollectionView.delegate = self
        
        appendButton.layer.cornerRadius = Metric.buttonRadius
        appendButton.layer.masksToBounds = true
        
        appendButton.setBackgroundColor(.appColor(.color4) ?? .red, for: .normal)
        
        diaryCollectionView.refreshControl = refreshControl
    }

    private func setupLayout() {
        [searchBar, diaryCollectionView].forEach {
            view.addSubview($0)

            $0.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.centerX.equalTo(view.snp.centerX)
            }
        }

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
        }

        diaryCollectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        [appendButton, appendButtonLabel].forEach {
            view.addSubview($0)
        }
        
        appendButton.snp.makeConstraints { make in
            make.width.equalTo(Metric.buttonWidthAndHeight)
            make.height.equalTo(Metric.buttonWidthAndHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(Metric.buttonOffset)
            make.trailing.equalTo(view.safeAreaLayoutGuide).offset(Metric.buttonOffset)
        }
        
        appendButtonLabel.snp.makeConstraints { make in
            make.centerX.equalTo(appendButton)
            make.centerY.equalTo(appendButton).offset(Metric.buttonLabelOffset)
        }
    }
    
    private func setupRx() {
        appendButton.rx.tap
            .withUnretained(self)
            .bind { _ in
                self.appendButtonTapped()
            }
            .disposed(by: disposeBag)
        
        refreshControl.rx.controlEvent(.valueChanged)
            .withUnretained(self)
            .subscribe(onNext: { _ in
                self.refresh()
            }).disposed(by: disposeBag)
    }
    
    private func setRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(singleTapMethod))
        diaryCollectionView.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
    }
    
    @objc private func singleTapMethod(sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func refresh(){
        getDatasource()
        updateSnapshot(with: searchBar.text)
        refreshControl.endRefreshing()
    }
    
    private func makeDataSource() -> DataSource {
        let cellRegistration = UICollectionView.CellRegistration<DiaryCell, DiaryListItem> { (cell, _, item) in
            cell.configure(with: item)
        }
        
        let dataSource = DataSource(collectionView: diaryCollectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration, for: indexPath, item: itemIdentifier
            )
        }
        
        return dataSource
    }
    
    private func bindDataSource() {
        viewModel.diaryListItems
            .subscribe(onNext: { [weak self] datas in
                self?.diaryCells = datas
                self?.updateSnapshot()
            })
            .disposed(by: disposeBag)
    }
    
    private func getDatasource() {
        viewModel.getDiaryList()
    }
    
    private func appendButtonTapped() {
        delegate?.diaryAppendButtonTapped()
    }
}

extension DiaryCollectionViewController: UICollectionViewDelegate {
    func makeCollectionViewLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        let cellWidth: CGFloat = UIScreen.main.bounds.width / 2 - 1
        
        layout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        return layout
    }
    
    func updateSnapshot(with filter: String? = nil) {
        var snapshot = Snapshot()
        snapshot.appendSections(Section.allCases)
        
        if let filter = filter, filter != "" {
            let filtered = diaryCells.filter { $0.title.contains(filter) }
            snapshot.appendItems(filtered)
        }
        else {
            snapshot.appendItems(diaryCells)
        }
        
        DispatchQueue.main.async {
            self.dataSource?.apply(snapshot)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource?.itemIdentifier(for: indexPath)?.identifier else { return }
        
        delegate?.diaryCellSelected(id: id)
    }
}

extension DiaryCollectionViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSnapshot(with: searchBar.text)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        updateSnapshot(with: searchBar.text)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        
        updateSnapshot(with: searchBar.text)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        updateSnapshot(with: searchBar.text)
    }
}
