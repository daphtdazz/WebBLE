//
//  Download.swift
//  WebBLE
//
//  Created by David Park on 21/10/2026.
//
import Foundation

struct Download {
    let url: URL
    let created: Date?

    var name: String { url.pathComponents.last ?? "" }
}

class DownloadManager {
    // MARK: - Statics
    static var downloadsDirectoryURL: URL {
        URL.documentsDirectory.appendingPathComponent("Downloads")
    }

    // MARK: - Implementation
    lazy var fm = FileManager.default

    func removeItem(at index: Int) throws {
        let download = downloads()[index]
        try fm.removeItem(at: download.url)
    }

    func downloads() -> [Download] {
        do {
            var files = try fm.contentsOfDirectory(
                at: Self.downloadsDirectoryURL,
                includingPropertiesForKeys: [.creationDateKey]
            ).map{
                Download(url: $0, created: fm.creationDateOfFile($0))
            }
            files.sort(by: {
                guard let d0 = $0.created else {
                    return false
                }
                guard let d1 = $1.created else {
                    return true
                }
                return d0 > d1
            })
            return files
        } catch let e {
            NSLog("Unable to inspect downloads directory: \(e)")
            return []
        }
    }
    func clearAll() {
        for download in downloads() {
            do {
                try fm.removeItem(at: download.url)
            } catch let e {
                NSLog("Unable to delete file \(download.name): \(e)")
            }
        }
    }
}

fileprivate extension FileManager {
    func creationDateOfFile(_ file: URL) -> Date? {
        do {
            return try self.attributesOfItem(
                atPath: file.path(percentEncoded: false)
            )[.creationDate] as? Date
        } catch {
            return nil
        }
    }
}
