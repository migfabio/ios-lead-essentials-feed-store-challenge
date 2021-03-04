//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CouchbaseLiteSwift

class CouchbaseLiteFeedStore: FeedStore {
	private lazy var database: Database = {
		let dbConfig = DatabaseConfiguration()
		dbConfig.directory = storeURL.path
		return try! Database(name: "feed-store", config: dbConfig)
	}()

	private let storeURL: URL

	init(storeURL: URL) {
		self.storeURL = storeURL
	}

	func deleteCachedFeed(completion: @escaping DeletionCompletion) {}

	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let dbItems: [MutableDictionaryObject] = feed.map { item -> [String: Any] in
			let json: [String: Any?] = [
				"id": item.id.uuidString,
				"description": item.description,
				"location": item.location,
				"url": item.url.absoluteString
			]
			return json.compactMapValues { $0 }
		}
		.map { MutableDictionaryObject(data: $0) }

		let cache = MutableDocument()
			.setArray(MutableArrayObject(data: dbItems), forKey: "feed")
			.setDouble(timestamp.timeIntervalSinceReferenceDate, forKey: "timestamp")

		try! database.saveDocument(cache)

		completion(nil)
	}

	func retrieve(completion: @escaping RetrievalCompletion) {
		let query = QueryBuilder
			.select(SelectResult.all())
			.from(DataSource.database(database))

		if let results = try? query.execute(),
		   let cache = results.allResults().first?.dictionary(forKey: "feed-store"),
		   let feed = cache.array(forKey: "feed")?.toArray() as? [[String: Any]] {
			let localFeed = feed.compactMap { item -> LocalFeedImage? in
				guard let idString = item["id"] as? String, let id = UUID(uuidString: idString),
					let description = item["description"] as? String?,
					let location = item["location"] as? String?,
					let urlString = item["url"] as? String, let url = URL(string: urlString) else {
					return nil
				}
				return LocalFeedImage(id: id, description: description, location: location, url: url)
			}
			completion(
				.found(
					feed: localFeed,
					timestamp: Date(timeIntervalSinceReferenceDate: cache.double(forKey: "timestamp"))
				)
			)
		} else {
			completion(.empty)
		}
	}
}

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {

	override func setUp() {
		super.setUp()
		let storeURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("test")
		try? FileManager.default.removeItem(at: storeURL)
	}

	override func tearDown() {
		super.tearDown()
		let storeURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("test")
		try? FileManager.default.removeItem(at: storeURL)
	}
	
	func test_retrieve_deliversEmptyOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() throws {
//		let sut = try makeSUT()
//
//		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> FeedStore {
		let storeURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("test")
		let sut = CouchbaseLiteFeedStore(storeURL: storeURL)
		addTeardownBlock { [weak sut] in
			XCTAssertNil(sut, file: file, line: line)
		}
		return sut
	}
	
}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

//extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {
//
//	func test_retrieve_deliversFailureOnRetrievalError() throws {
////		let sut = try makeSUT()
////
////		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
//	}
//
//	func test_retrieve_hasNoSideEffectsOnFailure() throws {
////		let sut = try makeSUT()
////
////		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {
//
//	func test_insert_deliversErrorOnInsertionError() throws {
////		let sut = try makeSUT()
////
////		assertThatInsertDeliversErrorOnInsertionError(on: sut)
//	}
//
//	func test_insert_hasNoSideEffectsOnInsertionError() throws {
////		let sut = try makeSUT()
////
////		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {
//
//	func test_delete_deliversErrorOnDeletionError() throws {
////		let sut = try makeSUT()
////
////		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
//	}
//
//	func test_delete_hasNoSideEffectsOnDeletionError() throws {
////		let sut = try makeSUT()
////
////		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
//	}
//
//}
