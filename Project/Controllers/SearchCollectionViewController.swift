//
//  SearchCollectionViewController.swift
//  Project
//
//  Created by Марина on 31.01.2020.
//  Copyright © 2020 Marina Potashenkova. All rights reserved.
//

import UIKit
import AlamofireImage

private let reuseIdentifier = "Track"

protocol SearchCollectionViewControllerDelegate: UIViewController {
    
    func play(trackNumber: Int)
    func stop()
}

class SearchCollectionViewController: UICollectionViewController {
    
    @IBOutlet weak var nameLabel: UIBarButtonItem!
    
    var user: User!
    
    var tracks: [Track]? = []
    var searchClient: SearchClient!
    static let imageCache = AutoPurgingImageCache()
    
    weak var delegate: SearchCollectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nameLabel.title = user.name
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let miniPlayerViewController = MiniPlayerViewController()
        miniPlayerViewController.view.frame = CGRect(x: 0, y: self.view.bounds.height - self.view.safeAreaInsets.bottom - 80, width: self.view.bounds.width, height: 80)
        self.addChild(miniPlayerViewController)
        view.addSubview(miniPlayerViewController.view)
        miniPlayerViewController.didMove(toParent: self)
        
    }
    
    @IBAction func signOut(_ sender: UIBarButtonItem) {
        delegate?.stop()
        Playlist.shared.tracks.removeAll()
        try? UserRepository.delete(from: "www.soundcloud.com")
        
        DispatchQueue.main.async {
            guard let authViewController = self.storyboard?.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
                assertionFailure("Error of casting UIViewController to AuthViewController")
                return
            }
                authViewController.modalPresentationStyle = .fullScreen
        self.navigationController?.tabBarController?.navigationController?.setViewControllers([authViewController], animated: true)
        }
        
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Playlist.shared.tracks.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? TrackCell
        else {
            assertionFailure("Error of downcasting UICollectionViewCell to TrackCell or getting track from SearchCollectionViewController")
            return UICollectionViewCell()
        }
        let track = Playlist.shared.tracks[indexPath.row]
        
        if let artworkUrl = Playlist.shared.tracks[indexPath.row].artworkUrl {
            
            cell.artworkImageView.af_setImage(withURL: artworkUrl, placeholderImage: UIImage(systemName: "music.note"), filter: RoundedCornersFilter(radius: 3.0)) { (response) in
                
                SearchCollectionViewController.imageCache.add(cell.artworkImageView.image!, for: URLRequest(url: artworkUrl), withIdentifier: String(track.id))
            }
        }
        
        cell.trackLabel.text = track.title
        cell.ownerLabel.text = track.owner.name
        
        cell.layer.borderWidth = 0.3
        cell.layer.borderColor = UIColor.lightGray.cgColor
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if Playlist.shared.tracks.count > 1 {
            if indexPath.row == Playlist.shared.tracks.count - 1 {
                search()
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if (kind == UICollectionView.elementKindSectionHeader) {
            let headerView: UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CollectionViewHeader", for: indexPath)
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        delegate?.play(trackNumber: indexPath.row)
    }
    
    // MARK: - Private methods
    
    private func search() {
        searchClient.search { [unowned self] (tracks) in
            Playlist.shared.tracks.append(contentsOf: tracks)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

}

// MARK: - UISearchBarDelegate

extension SearchCollectionViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        guard let query = searchBar.text, !query.isEmpty else {
            return
        }
        
        searchClient = SearchClient(query: query)
        search()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count == 0 {
            Playlist.shared.tracks.removeAll()
            self.collectionView.reloadData()
        }
    }
}

// MARK: - UICollectionViewDelegateLayout

extension SearchCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: CGFloat(80))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
