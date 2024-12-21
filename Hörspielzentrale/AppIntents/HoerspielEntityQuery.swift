//
//  HoerspielEntityQuery.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 07.09.24.
//

import AppIntents
import OSLog

/// A Query used to handle all ``HoerspielEntity``
struct HoerspielEntityQuery: EntityQuery {
    @Dependency
    var dataHandler: DataManager
    
    /// All Entities with a specified identifier
    /// - Parameter identifiers: The identifier to check against
    /// - Returns: Returns all entities that use a matching identifier
    func entities(for identifiers: [String]) async throws -> [Entity] {
        return try await dataHandler.entities(for: identifiers)
    }
}

extension HoerspielEntityQuery: EnumerableEntityQuery {
    /// All Hoerspiel Entities available
    /// - Returns: Returns an array of ``HoerspielEntity``
    func allEntities() async throws -> [HoerspielEntity] {
        Logger.appIntents.info("All entities was called")
        return try await dataHandler.allEntities()
    }
    
    /// Suggested Hoerspiel Entities that are likely to be used by the user in Shortcuts
    /// - Returns: Returns an array of ``HoerspielEntity``
    func suggestedEntities() async throws -> [HoerspielEntity] {
        Logger.appIntents.info("Suggested Entities called")
        let entities = try await dataHandler.suggestedEntities()
        return entities
    }
}

extension HoerspielEntityQuery: EntityStringQuery {
    /// Provides all Entities matching a search term
    /// - Parameter string: The search term all entities will be checked against
    /// - Returns: Returns all entities whose title contains the search term
    func entities(matching string: String) async throws -> [HoerspielEntity] {
        Logger.appIntents.info("Entities matching \(string)")
        return await dataHandler.entities(matching: string)
    }
}
