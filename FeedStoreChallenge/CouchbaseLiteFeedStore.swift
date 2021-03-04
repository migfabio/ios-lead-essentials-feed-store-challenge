//
//  CouchbaseLiteFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Fabio Mignogna on 04/03/2021.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CouchbaseLiteSwift
import Foundation

public class CouchbaseLiteFeedStore: FeedStore {
	private struct Cache {
		private let feed: [CouchbaseLiteFeedImage]
		private let timestamp: Date

		init(feed: [LocalFeedImage], timestamp: Date) {
			self.feed = feed.map(CouchbaseLiteFeedImage.init)
			self.timestamp = timestamp
		}

		var toDocument: MutableDocument {
			MutableDocument(id: "cache")
				.setArray(MutableArrayObject(data: feed.map { $0.toDictionaryObject }), forKey: "feed")
				.setDouble(timestamp.timeIntervalSinceReferenceDate, forKey: "timestamp")
		}
	}

	private struct CouchbaseLiteFeedImage {
		private let id: UUID
		private let description: String?
		private let location: String?
		private let url: URL

		var toDictionaryObject: DictionaryObject {
			MutableDictionaryObject(
				data: [
					"id": id.uuidString,
					"description": description,
					"location": location,
					"url": url.absoluteString
				].compactMapValues { $0 }
			)
		}

		init(localFeedImage: LocalFeedImage) {
			self.id = localFeedImage.id
			self.description = localFeedImage.description
			self.location = localFeedImage.location
			self.url = localFeedImage.url
		}
	}

	private lazy var database: Database = {
		let dbConfig = DatabaseConfiguration()
		dbConfig.directory = storeURL.path
		return try! Database(name: "feed-store", config: dbConfig)
	}()

	private let storeURL: URL
	private let queue = DispatchQueue(label: "\(CouchbaseLiteFeedStore.self).queue", qos: .userInitiated, attributes: .concurrent)

	public init(storeURL: URL) {
		self.storeURL = storeURL
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		let database = self.database
		queue.async(flags: .barrier) {
			if let cache = database.document(withID: "cache") {
				try! database.deleteDocument(cache)
			}
			completion(nil)
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let database = self.database
		queue.async(flags: .barrier) {
			let cache = Cache(feed: feed, timestamp: timestamp)
			try! database.saveDocument(cache.toDocument)
			completion(nil)
		}
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		let database = self.database
		queue.async {
			guard let cache = database.document(withID: "cache"),
				  let result = cache.array(forKey: "feed")?.toArray() as? [[String: Any]] else {
				return completion(.empty)
			}

			let feed = self.makeLocalFeedImages(from: result)
			let timestamp = self.makeTimestamp(from:  cache.double(forKey: "timestamp"))
			completion(.found(feed: feed, timestamp: timestamp))
		}
	}

	private func makeLocalFeedImages(from result: [[String: Any]]) -> [LocalFeedImage] {
		result.compactMap {
			guard let idString = $0["id"] as? String, let id = UUID(uuidString: idString),
				  let description = $0["description"] as? String?,
				  let location = $0["location"] as? String?,
				  let urlString = $0["url"] as? String, let url = URL(string: urlString) else {
				return nil
			}
			return LocalFeedImage(id: id, description: description, location: location, url: url)
		}
	}

	private func makeTimestamp(from result: TimeInterval) -> Date {
		Date(timeIntervalSinceReferenceDate: result)
	}
}
