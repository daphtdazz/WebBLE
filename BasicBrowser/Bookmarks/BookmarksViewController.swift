//
//  BookmarksViewController.swift
//  BleBrowser
//
//  Created by David Park on 13/01/2017.
//  Copyright © 2017 David Park. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

class BookmarksViewController: UITableViewController {

    // MARK: - Event handling
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem
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
        return true
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookmark", for: indexPath)

        let bm = BUD.bookmarks[indexPath.item]
        var cc = cell.defaultContentConfiguration()
        cc.text = bm.title
        cc.secondaryText = bm.assumedHTTPSURLPath
        cell.contentConfiguration = cc

        return cell
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let srci = indexPath.item
        switch editingStyle {
        case .delete:
            self.tableView.beginUpdates()
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            BUD.bookmarks.remove(at: srci)
            self.tableView.endUpdates()
        default: break
            
        }
    }
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let srci = sourceIndexPath.item
        let dsti = destinationIndexPath.item

        BUD.bookmarks.move(from: srci, to: dsti)

    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BUD.bookmarks.count
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
}
