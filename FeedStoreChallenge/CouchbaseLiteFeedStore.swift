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
		let feed: [LocalFeedImage]
		let timestamp: Date

		var toDocument: MutableDocument {
			MutableDocument(id: "cache")
				.setArray(MutableArrayObject(data: feed.map { $0.toDictionaryObject }), forKey: "feed")
				.setDouble(timestamp.timeIntervalSinceReferenceDate, forKey: "timestamp")
		}

		init(feed: [LocalFeedImage], timestamp: Date) {
			self.feed = feed
			self.timestamp = timestamp
		}

		init?(document: Document) {
			guard let feedJSON = document.array(forKey: "feed") else {
				return nil
			}
			self.feed = feedJSON.reduce(into: [DictionaryObject]()) { output, element in
				if let dicationary = element as? DictionaryObject {
					output.append(dicationary)
				}
			}.compactMap(LocalFeedImage.init)
			self.timestamp = Date(timeIntervalSinceReferenceDate: document.double(forKey: "timestamp"))
		}
	}

	private lazy var database: Database? = {
		let dbConfig = DatabaseConfiguration()
		dbConfig.directory = storeURL.path
		return try? Database(name: "feed-store", config: dbConfig)
	}()

	private let storeURL: URL
	private let queue = DispatchQueue(
		label: "\(CouchbaseLiteFeedStore.self).queue",
		qos: .userInitiated,
		attributes: .concurrent
	)

	public init(storeURL: URL) {
		self.storeURL = storeURL
	}

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		guard let database = database else {
			return completion(nil)
		}

		queue.async(flags: .barrier) {
			guard let cache = database.document(withID: "cache") else {
				return completion(nil)
			}

			do {
				try database.deleteDocument(cache)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		guard let database = database else {
			return completion(nil)
		}

		queue.async(flags: .barrier) {
			do {
				try database.saveDocument(Cache(feed: feed, timestamp: timestamp).toDocument)
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	public func retrieve(completion: @escaping RetrievalCompletion) {
		guard let database = database else {
			return completion(.empty)
		}

		queue.async {
			guard let cacheDocument = database.document(withID: "cache"),
				  let cache = Cache(document: cacheDocument) else {
				return completion(.empty)

			}

			completion(
				.found(
					feed: cache.feed.map { $0.toLocalFeedImage },
					timestamp: cache.timestamp
				)
			)
		}
	}
}

private extension LocalFeedImage {
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

	var toLocalFeedImage: LocalFeedImage {
		LocalFeedImage(id: id, description: description, location: location, url: url)
	}

	init?(json: DictionaryObject) {
		guard let idString = json.string(forKey: "id"), let id = UUID(uuidString: idString),
			  let urlString = json.string(forKey: "url"), let url = URL(string: urlString) else {
			return nil
		}

		self.id = id
		self.description = json.string(forKey: "description")
		self.location = json.string(forKey: "location")
		self.url = url
	}
}
