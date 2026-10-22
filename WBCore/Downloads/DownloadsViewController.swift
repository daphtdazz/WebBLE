//
//  DownloadsViewController.swift
//  WebBLE
//
//  Created by David Park on 21/10/2026.
//
import UIKit

class DownloadsContainerViewController: UIViewController {
    // MARK: - Statics
    static func openDownloadsInFiles() {
        let dlPath = DownloadManager.downloadsDirectoryURL.path()
        let app = UIApplication.shared
        if let dlURL = URL(string: "shareddocuments://\(dlPath)"),
            app.canOpenURL(dlURL)
        {
            app.open(dlURL)
        }
    }

    // MARK: - UI Primaries
    @IBAction func openDownloadsInFiles() {
        Self.openDownloadsInFiles()
    }

    // MARK: - View controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem =
            (self.children[0] as! DownloadsViewController).clearButton
    }
}

class DownloadsViewController: UITableViewController {

    // MARK: - UI primaries
    @IBOutlet var noDownloadsView: UIView!
    @IBOutlet var openInFilesButtonView: UIView!
    @IBAction @objc func clearAllDownloads() {
        downloadManager.clearAll()
        self.tableView.reloadData()
    }

    lazy var clearButton: UIBarButtonItem = {
        var but = UIBarButtonItem(
            title: "Delete all",
            style: .plain,
            target: self,
            action: #selector(clearAllDownloads)
        )
        but.tintColor = .systemRed
        return but
    }()

    // MARK: - Implementation
    let downloadManager = DownloadManager()

    // MARK: - Base View Controller overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.clearButton
    }

    override func viewWillAppear(_ animated: Bool) {
        let nc = self.navigationController!
        nc.setToolbarHidden(true, animated: true)
        nc.setNavigationBarHidden(false, animated: true)
        nc.hidesBarsOnSwipe = false
    }

    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "download", for: indexPath)

        var cc = cell.defaultContentConfiguration()
        let download = downloadManager.downloads()[indexPath.item]
        cc.text = download.name
        cc.secondaryText =
            download.created?.formatted(
                Date
                    .FormatStyle()
                    .year(.defaultDigits)
                    .month(.twoDigits)
                    .day(.twoDigits)
                    .hour(.defaultDigits(amPM: .abbreviated))
                    .minute(.twoDigits)
            ) ?? "<unknown date>"
        cell.contentConfiguration = cc
        return cell
    }
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        let srci = indexPath.item
        switch editingStyle {
        case .delete:
            do {
                try downloadManager.removeItem(at: srci)
            } catch let e {
                NSLog("Failed to delete file: \(e)")
                return
            }
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        default: break

        }
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numItems = downloadManager.downloads().count
        noDownloadsView.isHidden = numItems > 0
        return numItems
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int)
        -> String?
    {
        return nil
    }
}
