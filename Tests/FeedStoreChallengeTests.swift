//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge
import CouchbaseLiteSwift

class CouchbaseLiteFeedStore: FeedStore {
	private struct Cache {
		private let feed: [CouchbaseLiteFeedImage]
		private let timestamp: Date

		init(feed: [LocalFeedImage], timestamp: Date) {
			self.feed = feed.map(CouchbaseLiteFeedImage.init)
			self.timestamp = timestamp
		}

		var toDocument: MutableDocument {
			MutableDocument()
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

	init(storeURL: URL) {
		self.storeURL = storeURL
	}

	func deleteCachedFeed(completion: @escaping DeletionCompletion) {}

	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let cache = Cache(feed: feed, timestamp: timestamp)
		try! database.saveDocument(cache.toDocument)
		completion(nil)
	}

	func retrieve(completion: @escaping RetrievalCompletion) {
		let query = QueryBuilder
			.select(SelectResult.all())
			.from(DataSource.database(database))

		guard let results = try? query.execute(),
			  let result = results.allResults().first?.dictionary(forKey: "feed-store"),
			  let feedArray = result.array(forKey: "feed")?.toArray() as? [[String: Any]]
		else {
			return completion(.empty)
		}

		let feed = makeLocalFeedImages(from: feedArray)
		let timestamp = makeTimestamp(from:  result.double(forKey: "timestamp"))
		completion(.found(feed: feed, timestamp: timestamp))
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

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {

	override func setUp() {
		super.setUp()
		setupEmptyStoreState()
	}

	override func tearDown() {
		super.tearDown()
		undoStoreSideEffects()
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
		let sut = try makeSUT()

		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
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
		let sut = CouchbaseLiteFeedStore(storeURL: storeURL())
		addTeardownBlock { [weak sut] in
			XCTAssertNil(sut, file: file, line: line)
		}
		return sut
	}

	private func storeURL() -> URL {
		FileManager.default
			.temporaryDirectory
			.appendingPathComponent("\(type(of: self))")
	}

	private func setupEmptyStoreState() {
		deleteStoreArtifacts()
	}

	private func undoStoreSideEffects() {
		deleteStoreArtifacts()
	}

	private func deleteStoreArtifacts() {
		try? FileManager.default.removeItem(at: storeURL())
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
