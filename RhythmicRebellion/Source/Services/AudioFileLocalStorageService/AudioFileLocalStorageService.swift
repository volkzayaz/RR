//
//  AudioFileLocalStorageService.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/9/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

protocol AudioFileLocalStorageServiceObserver: class {
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didStartDownload trackAudioFile: TrackAudioFile)
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didFinishDownload trackAudioFile: TrackAudioFile)
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didCancelDownload trackAudioFile: TrackAudioFile)
}

extension AudioFileLocalStorageServiceObserver {
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didStartDownload trackAudioFile: TrackAudioFile) { }
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didFinishDownload trackAudioFile: TrackAudioFile) { }
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didCancelDownload trackAudioFile: TrackAudioFile) { }
}


class AudioFileLocalStorageService: NSObject, Observable {

    typealias ObserverType = AudioFileLocalStorageServiceObserver
    let observersContainer = ObserversContainer<ObserverType>()


    enum AudioFileState {
        case downloaded(String)
        case loading(Progress)
    }

    let syncQueue: DispatchQueue

    var items: [Int: TrackAudioFileLocalItem]
    var tasks: [Int : URLSessionTask]

    var downloadSessionIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "RhythmicRebellion" + "." + "DownloadSession"
    }

    private lazy var fileURL: URL = {
        let applicationSupportDirectoryURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        return applicationSupportDirectoryURL.appendingPathComponent("audioFileLocalStorage.json")
    }()

    var documentDirectoryURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var internalDownloadSession: URLSession?
    var downloadSession: URLSession {
        get {
            guard let downloadSession = internalDownloadSession else {
                let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: self.downloadSessionIdentifier)
                sessionConfiguration.sessionSendsLaunchEvents = true
                sessionConfiguration.allowsCellularAccess = true
                let downloadSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)

                internalDownloadSession = downloadSession

                return downloadSession
            }

            return downloadSession
        }
    }

    var downloadSessionBackgroundCompletionHandler: (() -> Void)?

    let downloadSessionPolicyManager = ServerTrustPolicyManager(policies: [ : ])

    override init() {

        self.syncQueue = DispatchQueue(label: Bundle.main.bundleIdentifier ?? "RhythmicRebellion" + "." + "AudioFileLocalStorage")
        self.items = [ : ]
        self.tasks = [ : ]

        super.init()

        self.load()
        self.restoreSession()

    }

    func restoreSession() {

        self.downloadSession.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in

            self.syncQueue.sync {
                for downloadTask in downloadTasks {
                    self.tasks[downloadTask.taskIdentifier] = downloadTask
                }
            }
        }
    }

    func reset() {
        self.syncQueue.sync {
            self.downloadSession.invalidateAndCancel()
            self.tasks.removeAll()
            self.items.removeAll()

            do {
                let fileManager = FileManager.default
                let localAudioFilesURLs = try fileManager.contentsOfDirectory(at: ModelSupport.sharedInstance.documentDirectoryURL,
                                                                              includingPropertiesForKeys: nil,
                                                                              options: [.skipsSubdirectoryDescendants])

                for localAudioFileURL in localAudioFilesURLs {
                    try fileManager.removeItem(at: localAudioFileURL)
                }

            } catch {
                print("Error: error")
            }

            self.save()
            self.internalDownloadSession = nil
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: self.fileURL)
            self.items = try JSONDecoder().decode([Int: TrackAudioFileLocalItem].self, from: data)
        } catch {
            print("AudioFileLocalStorageService loading error: \(error)")
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(self.items)
            let fileManager = FileManager.default

            if fileManager.fileExists(atPath: self.fileURL.path, isDirectory: nil) == false {
                try fileManager.createDirectory(at: self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            } else {
                try fileManager.removeItem(at: self.fileURL)
            }
            try data.write(to: self.fileURL, options: [])

        } catch {
            print("AudioFileLocalStorageService saving error: \(error)")
        }
    }

    func state(for trackAudioFile: TrackAudioFile) -> TrackAudioFileLocalItemState? {

        var state: TrackAudioFileLocalItemState? = nil

        self.syncQueue.sync {
            guard let item = self.items[trackAudioFile.id] else { return }
            state = item.state
        }

        return state
    }

    func download(trackAudioFile: TrackAudioFile) {

        guard let downloadURL = URL(string: trackAudioFile.urlString) else { return }

        self.syncQueue.sync {
            let downloadTask = self.downloadSession.downloadTask(with: downloadURL)
            self.tasks[downloadTask.taskIdentifier] = downloadTask
            self.items[trackAudioFile.id] = TrackAudioFileLocalItem(trackAudioFile: trackAudioFile,
                                                                    state: .downloading(downloadTask.taskIdentifier, Progress(totalUnitCount: 0)))

            self.save()

            downloadTask.resume()
        }

        DispatchQueue.main.async {
            self.observersContainer.invoke { (observer) in
                observer.audioFileLocalStorageService(self, didStartDownload: trackAudioFile)
            }
        }
    }

    func cancelDownloading(for trackAudioFile: TrackAudioFile) {

        var shouldNotify = false

        self.syncQueue.sync {
            guard let item = self.items[trackAudioFile.id] else { return }

            switch item.state {
            case .downloading(let taskId, _):
                guard let task = self.tasks[taskId] else { return }

                task.cancel()
                self.items[trackAudioFile.id] = nil
                shouldNotify = true

            default: break
            }
        }

        if shouldNotify {
            DispatchQueue.main.async {
                self.observersContainer.invoke { (observer) in
                    observer.audioFileLocalStorageService(self, didCancelDownload: trackAudioFile)
                }
            }
        }
    }

    func suggestedFileURL(for fileURL: URL) -> URL {

        let fileManager = FileManager.default

        var suggestedFileURL = fileURL
        var index = 0

        while fileManager.fileExists(atPath: suggestedFileURL.path) {
            let extention = suggestedFileURL.pathExtension
            suggestedFileURL.deletePathExtension()
            let lastPathComponent = suggestedFileURL.lastPathComponent
            suggestedFileURL.deleteLastPathComponent()

            index += 1

            suggestedFileURL.appendPathComponent(lastPathComponent + String(index))
            suggestedFileURL.appendPathExtension(extention)
        }

        return suggestedFileURL
    }

}

extension AudioFileLocalStorageService: URLSessionDownloadDelegate {

    // MARK: NSURLSessionDelegate
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
//        self.removeAllSessionDownloadTaskDelegate()
        print("URLSessiondidBecomeInvalidWithError: \(String(describing: error))")

        self.syncQueue.sync {
            self.tasks.removeAll()
            self.items = self.items.filter {
                switch $0.value.state {
                    case .downloaded(_): return true
                default: return false
                }
            }

            self.save()
        }
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let host = challenge.protectionSpace.host

            if let serverTrustPolicy = self.downloadSessionPolicyManager.serverTrustPolicy(forHost: host),
                let serverTrust = challenge.protectionSpace.serverTrust {

                if serverTrustPolicy.evaluate(serverTrust, forHost: host) {
                    disposition = .useCredential
                    credential = URLCredential(trust: serverTrust)
                } else {
                    disposition = .cancelAuthenticationChallenge
                }
            }
        }

        completionHandler(disposition, credential)    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("URLSessionDidFinishEventsForBackgroundURLSession: \(session)")

        self.downloadSessionBackgroundCompletionHandler?()
        self.downloadSessionBackgroundCompletionHandler  = nil
    }

    // MARK: NSURLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: (URLRequest?) -> Void) {

        completionHandler(request)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let host = challenge.protectionSpace.host

            if let serverTrustPolicy = self.downloadSessionPolicyManager.serverTrustPolicy(forHost: host),
                let serverTrust = challenge.protectionSpace.serverTrust
            {
                if serverTrustPolicy.evaluate(serverTrust, forHost: host) {
                    disposition = .useCredential
                    credential = URLCredential(trust: serverTrust)
                } else {
                    disposition = .cancelAuthenticationChallenge
                }
            }
        } else {
            if challenge.previousFailureCount > 0 {
                disposition = .rejectProtectionSpace
            }
        }

        completionHandler(disposition, credential)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: (InputStream?) -> Void) {
        var inputStream: InputStream? = nil;

        if let httpBodyStream = task.originalRequest?.httpBodyStream, httpBodyStream.self is NSCopying {
            inputStream = task.originalRequest?.httpBodyStream?.copy() as? InputStream
        }

        completionHandler(inputStream);
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        if #available(iOS 11.0, *) {
            print("didSendBodyData task.progress: \(task.progress)")
        } else {
            // Fallback on earlier versions
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.syncQueue.sync {
            guard let _ = self.tasks[task.taskIdentifier] else { return }

            self.tasks[task.taskIdentifier] = nil

            guard error != nil, let item = self.items.filter ({
                switch $0.value.state {
                case .downloading(let taskIdentifier, _): return taskIdentifier == task.taskIdentifier
                default: return false
                }
            }).first?.value else { self.save(); return }

            self.items[item.trackAudioFile.id] = nil
            self.save()
        }
    }

    // MARK: NSURLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        var trackAudioFile: TrackAudioFile?

        self.syncQueue.sync {
            guard let item = self.items.filter ({
                switch $0.value.state {
                case .downloading(let taskIdentifier, _): return taskIdentifier == downloadTask.taskIdentifier
                default: return false
                }
            }).first?.value else { return }

            do {
                let itemLocalURL = ModelSupport.sharedInstance.documentDirectoryURL.appendingPathComponent(item.trackAudioFile.originalName)
                let itemSuggestedLocalURL = self.suggestedFileURL(for: itemLocalURL)
                try FileManager.default.copyItem(at: location, to: itemSuggestedLocalURL)

                item.state = .downloaded(itemSuggestedLocalURL)
            } catch {
                self.items[item.trackAudioFile.id] = nil
                print(print("AudioFileLocalStorageService copy item error: \(error)"))
            }

            save()

            trackAudioFile = item.trackAudioFile
        }

        if let downloadedTrackAudioFile = trackAudioFile {
            DispatchQueue.main.async {
                self.observersContainer.invoke { (observer) in
                    observer.audioFileLocalStorageService(self, didFinishDownload: downloadedTrackAudioFile)
                }
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

//        if #available(iOS 11.0, *) {
//            print("didWriteData task.progress: \(downloadTask.progress)")
//        }

        self.syncQueue.sync {

            guard let item = self.items.filter ({
                switch $0.value.state {
                case .downloading(let taskIdentifier, _): return taskIdentifier == downloadTask.taskIdentifier
                default: return false
                }
                }).first?.value else { return }

            switch item.state {
            case .downloading(_, let progress):
                progress.totalUnitCount = totalBytesExpectedToWrite
                progress.completedUnitCount = totalBytesWritten
            default: break
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {

//        if #available(iOS 11.0, *) {
//            print("didWriteData task.progress: \(downloadTask.progress)")
//        }

        self.syncQueue.sync {

            guard let item = self.items.filter ({
                switch $0.value.state {
                case .downloading(let taskIdentifier, _): return taskIdentifier == downloadTask.taskIdentifier
                default: return false
                }
            }).first?.value else { return }

            switch item.state {
            case .downloading(_, let progress):

                progress.totalUnitCount = expectedTotalBytes
                progress.completedUnitCount = fileOffset
            default: break
            }
        }
    }
}

