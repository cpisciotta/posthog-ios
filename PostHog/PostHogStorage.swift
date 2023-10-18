//
//  PostHogStorage.swift
//  PostHog
//
//  Created by Ben White on 08.02.23.
//

import Foundation

/**
 # Storage

 posthog-ios stores data either to file or to UserDefaults in order to support tvOS. As recordings won't work on tvOS anyways and we have no tvOS users so far,
 we are opting to only support iOS via File storage.
 */

func applicationSupportDirectoryURL() -> URL {
    let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return url.appendingPathComponent(Bundle.main.bundleIdentifier!)
}

class PostHogStorage {
    enum StorageKey: String {
        case distinctId = "posthog.distinctId"
        case anonymousId = "posthog.anonymousId"
        case queue = "posthog.queueFolder" // NOTE: This is different to posthog-ios as we don't want to touch the other queue
        case enabledFeatureFlags = "posthog.enabledFeatureFlags"
        case enabledFeatureFlagPayloads = "posthog.enabledFeatureFlagPayloads"
        case groups = "posthog.groups"
        case sessionId = "posthog.sessionId"
        case sessionlastTimestamp = "posthog.sessionlastTimestamp"
        case registerProperties = "posthog.registerProperties"
        case optOut = "posthog.optOut"
    }

    private let config: PostHogConfig

    // The location for storing data that we always want to keep
    let appFolderUrl: URL

    init(_ config: PostHogConfig) {
        self.config = config

        appFolderUrl = applicationSupportDirectoryURL()

        createDirectoryAtURLIfNeeded(url: appFolderUrl)
    }

    private func createDirectoryAtURLIfNeeded(url: URL) {
        if FileManager.default.fileExists(atPath: url.path, isDirectory: nil) { return }
        do {
            try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true)
        } catch {
            hedgeLog("Error creating storage directory: \(error.localizedDescription)")
        }
    }

    public func url(forKey key: StorageKey) -> URL {
        appFolderUrl.appendingPathComponent(key.rawValue)
    }

    // The "data" methods are the core for storing data and differ between Modes
    // All other typed storage methods call these
    private func getData(forKey: StorageKey) -> Data? {
        let url = url(forKey: forKey)

        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            return nil
        }
    }

    private func setData(forKey: StorageKey, contents: Data?) {
        var url = url(forKey: forKey)

        do {
            if contents == nil {
                try FileManager.default.removeItem(at: url)
                return
            }

            try contents?.write(to: url)

            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? url.setResourceValues(resourceValues)

        } catch {
            hedgeLog("Failed to write data for key '\(forKey)' error: \(error.localizedDescription)")
        }
    }

    private func getJson(forKey key: StorageKey) -> Any? {
        guard let data = getData(forKey: key) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private func setJson(forKey key: StorageKey, json: Any) {
        var jsonObject: Any?

        if let dictionary = json as? [AnyHashable: Any] {
            jsonObject = dictionary
        } else if let array = json as? [Any] {
            jsonObject = array
        } else {
            // TRICKY: This is weird legacy behaviour storing the data as a dictionary
            jsonObject = [key.rawValue: json]
        }

        let data = try? JSONSerialization.data(withJSONObject: jsonObject!)
        setData(forKey: key, contents: data)
    }

    public func reset() {
        do {
            try FileManager.default.removeItem(at: appFolderUrl)
            createDirectoryAtURLIfNeeded(url: appFolderUrl)
        } catch {
            hedgeLog("Failed to reset storage folder, error: \(error.localizedDescription)")
        }
    }

    public func remove(key: StorageKey) {
        let url = url(forKey: key)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            hedgeLog("Failed to remove key '\(key)', error: \(error.localizedDescription)")
        }
    }

    public func getString(forKey key: StorageKey) -> String? {
        let value = getJson(forKey: key)
        if let stringValue = value as? String {
            return stringValue
        } else if let dictValue = value as? [String: String] {
            return dictValue[key.rawValue]
        }
        return nil
    }

    public func setString(forKey key: StorageKey, contents: String) {
        setJson(forKey: key, json: contents)
    }

    public func getNumber(forKey key: StorageKey) -> Double? {
        let value = getJson(forKey: key)
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let dictValue = value as? [String: Double] {
            return dictValue[key.rawValue]
        }
        return nil
    }

    public func setNumber(forKey key: StorageKey, contents: Double) {
        setJson(forKey: key, json: contents)
    }

    public func getDictionary(forKey key: StorageKey) -> [AnyHashable: Any]? {
        getJson(forKey: key) as? [AnyHashable: Any]
    }

    public func setDictionary(forKey key: StorageKey, contents: [AnyHashable: Any]) {
        setJson(forKey: key, json: contents)
    }

    public func getArray(forKey key: StorageKey) -> [Any]? {
        getJson(forKey: key) as? [Any]
    }

    public func setArray(forKey key: StorageKey, contents: [Any]) {
        setJson(forKey: key, json: contents)
    }

    public func getBool(forKey key: StorageKey) -> Bool? {
        getJson(forKey: key) as? Bool
    }

    public func setBool(forKey key: StorageKey, contents: Bool) {
        setJson(forKey: key, json: contents)
    }
}
