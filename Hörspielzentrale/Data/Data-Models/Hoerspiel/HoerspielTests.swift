//
//  HoerspielTests.swift
//  Hörspielzentrale
//
//  Created by Philipp Steiner on 12.01.25.
//

import Foundation
import Testing
import MusicKit

@Suite("Hörspiel Tests")
struct HoerspielTests {
    // MARK: - Hoerspiel
    @Test func hoerspielFromConcrete() throws {
        let title = "Folge 17: Rette Atlantis"
        let albumID = "1092526143"
        let played = false
        let lastPlayed = Date.distantPast
        let playedUpTo = 0
        let showInUpNext = false
        let addedToUpNext = Date.distantPast
        let duration = 4725.989000000001
        let releaseDate = Date(timeIntervalSince1970: 1285884000)
        let artist = "Die drei ??? Kids"
        let upc = "886445747867"
        let tracks = [StoredTrack]()
        let series = Series.example
        
        let hoerspiel = Hoerspiel(title: title,
                                  albumID: albumID,
                                  played: played,
                                  lastPlayed: lastPlayed,
                                  playedUpTo: playedUpTo,
                                  showInUpNext: showInUpNext,
                                  addedToUpNext: addedToUpNext,
                                  duration: duration,
                                  releaseDate: releaseDate,
                                  artist: artist,
                                  upc: upc,
                                  tracks: tracks,
                                  series: series)
        #expect(title == hoerspiel.title)
        #expect(albumID == hoerspiel.albumID)
        #expect(played == hoerspiel.played)
        #expect(lastPlayed == hoerspiel.lastPlayed)
        #expect(playedUpTo == hoerspiel.playedUpTo)
        #expect(showInUpNext == hoerspiel.showInUpNext)
        #expect(addedToUpNext == hoerspiel.addedToUpNext)
        #expect(duration == hoerspiel.duration)
        #expect(releaseDate == hoerspiel.releaseDate)
        #expect(artist == hoerspiel.artist)
        #expect(upc == hoerspiel.upc)
        #expect(tracks == hoerspiel.tracks)
        #expect(series == hoerspiel.series)
    }
    
    @Test func hoerspielFromCodable() throws {
        let codable = CodableHoerspiel.example
        let hoerspiel = Hoerspiel(codable)
        #expect(codable.title == hoerspiel.title)
        #expect(codable.albumID == hoerspiel.albumID)
        #expect(codable.duration == hoerspiel.duration)
        #expect(codable.releaseDate == hoerspiel.releaseDate)
        #expect(codable.artist == hoerspiel.artist)
        #expect(codable.upc == hoerspiel.upc)
        #expect(codable.lastPlayed == hoerspiel.lastPlayed)
        #expect(codable.playedUpTo == hoerspiel.playedUpTo)
        #expect(codable.played == hoerspiel.played)
    }
    
    @Test func hoerspielFromSendable() throws {
        let sendable = SendableHoerspiel.example
        let series = Series.example
        let hoerspiel = Hoerspiel(from: sendable, series: series)
        #expect(sendable.title == hoerspiel.title)
        #expect(sendable.albumID == hoerspiel.albumID)
        #expect(sendable.played == hoerspiel.played)
        #expect(sendable.lastPlayed == hoerspiel.lastPlayed)
        #expect(sendable.playedUpTo == hoerspiel.playedUpTo)
        #expect(sendable.showInUpNext == hoerspiel.showInUpNext)
        #expect(sendable.addedToUpNext == hoerspiel.addedToUpNext)
        #expect(sendable.duration == hoerspiel.duration)
        #expect(sendable.releaseDate == hoerspiel.releaseDate)
        #expect(sendable.artist == hoerspiel.artist)
        #expect(sendable.upc == hoerspiel.upc)
        #expect(sendable.tracks == hoerspiel.tracks?.compactMap( { SendableStoredTrack($0)}) ?? [])
    }
    
    // MARK: - SendableHoerspiel
    @Test func sendableFromHoerspiel() throws {
        let hoerspiel = Hoerspiel.example
        let sendable = SendableHoerspiel(hoerspiel: hoerspiel)
        #expect(sendable.title == hoerspiel.title)
        #expect(sendable.albumID == hoerspiel.albumID)
        #expect(sendable.played == hoerspiel.played)
        #expect(sendable.lastPlayed == hoerspiel.lastPlayed)
        #expect(sendable.playedUpTo == hoerspiel.playedUpTo)
        #expect(sendable.showInUpNext == hoerspiel.showInUpNext)
        #expect(sendable.addedToUpNext == hoerspiel.addedToUpNext)
        #expect(sendable.duration == hoerspiel.duration)
        #expect(sendable.releaseDate == hoerspiel.releaseDate)
        #expect(sendable.artist == hoerspiel.artist)
        #expect(sendable.persistentModelID == hoerspiel.persistentModelID)
        #expect(sendable.upc == hoerspiel.upc)
        #expect(sendable.tracks == hoerspiel.tracks?.compactMap( { SendableStoredTrack($0)}) ?? [])
        if let series = hoerspiel.series {
            #expect(sendable.series == SendableSeries(series))
        }
    }
    
    @Test func sendableFromConcrete() throws {
        let title = "Folge 17: Rette Atlantis"
        let albumID = "1092526143"
        let played = false
        let lastPlayed = Date.distantPast
        let playedUpTo = 0
        let showInUpNext = false
        let addedToUpNext = Date.distantPast
        let duration = 4725.989000000001
        let releaseDate = Date(timeIntervalSince1970: 1285884000)
        let artist = "Die drei ??? Kids"
        let upc = "886445747867"
        let tracks = [SendableStoredTrack]()
        let series = SendableSeries(Series.example)
        
        let hoerspiel = SendableHoerspiel(title: title,
                                          albumID: albumID,
                                          played: played,
                                          lastPlayed: lastPlayed,
                                          playedUpTo: playedUpTo,
                                          showInUpNext: showInUpNext,
                                          addedToUpNext: addedToUpNext,
                                          duration: duration,
                                          releaseDate: releaseDate,
                                          artist: artist,
                                          persistentModelID: Hoerspiel.example.persistentModelID,
                                          upc: upc,
                                          tracks: tracks,
                                          series: series)
        #expect(title == hoerspiel.title)
        #expect(albumID == hoerspiel.albumID)
        #expect(played == hoerspiel.played)
        #expect(lastPlayed == hoerspiel.lastPlayed)
        #expect(playedUpTo == hoerspiel.playedUpTo)
        #expect(showInUpNext == hoerspiel.showInUpNext)
        #expect(addedToUpNext == hoerspiel.addedToUpNext)
        #expect(duration == hoerspiel.duration)
        #expect(releaseDate == hoerspiel.releaseDate)
        #expect(artist == hoerspiel.artist)
        #expect(Hoerspiel.example.persistentModelID == hoerspiel.persistentModelID)
        #expect(upc == hoerspiel.upc)
        #expect(tracks == hoerspiel.tracks)
        #expect(series == hoerspiel.series)
    }
    
    // MARK: - CodableHoerspiel
    @Test func codableFromHoerspiel() async throws {
        let hoerspiel = Hoerspiel.example
        let codable = CodableHoerspiel(hoerspiel: hoerspiel)
        #expect(codable.title == hoerspiel.title)
        #expect(codable.albumID == hoerspiel.albumID)
        #expect(codable.duration == hoerspiel.duration)
        #expect(codable.releaseDate == hoerspiel.releaseDate)
        #expect(codable.artist == hoerspiel.artist)
        #expect(codable.upc == hoerspiel.upc)
        #expect(codable.lastPlayed == hoerspiel.lastPlayed)
        #expect(codable.playedUpTo == hoerspiel.playedUpTo)
        #expect(codable.played == hoerspiel.played)
    }
    
    @Test func codableFromConcrete() async throws {
        let title = "Folge 17: Rette Atlantis!"
        let albumID = "1092526143"
        let duration = 4725.989000000001
        let releaseDate = Date(timeIntervalSince1970: 1285891200)
        let artist = "Die drei ??? Kids"
        let upc = "886445747867"
        let lastPlayed = Date.distantPast
        let playedUpTo = 0
        let played = false
        let codable = CodableHoerspiel(title: title,
                                       albumID: albumID,
                                       duration: duration,
                                       releaseDate: releaseDate,
                                       artist: artist,
                                       upc: upc,
                                       lastPlayed: lastPlayed,
                                       playedUpTo: playedUpTo,
                                       played: played)
        #expect(codable.title == title)
        #expect(codable.albumID == albumID)
        #expect(codable.duration == duration)
        #expect(codable.releaseDate == releaseDate)
        #expect(codable.artist == artist)
        #expect(codable.upc == upc)
        #expect(codable.lastPlayed == lastPlayed)
        #expect(codable.playedUpTo == playedUpTo)
        #expect(codable.played == played)
    }
    
    @Test func codableFromAlbum() async throws {
        let request = MusicCatalogResourceRequest<Album>(matching: \.upc, equalTo: CodableHoerspiel.example.upc)
        let response = try await request.response()
        let responseAlbum = try #require(try await response.items.first?.with(.tracks))
        let album = CodableHoerspiel(responseAlbum)
        let example = CodableHoerspiel.example
        try #require(album != nil)
        #expect(album?.title == example.title)
        #expect(album?.albumID == example.albumID)
        #expect(album?.duration == example.duration)
        #expect(album?.releaseDate == example.releaseDate)
        #expect(album?.artist == example.artist)
        #expect(album?.upc == example.upc)
        #expect(album?.lastPlayed == example.lastPlayed)
        #expect(album?.playedUpTo == example.playedUpTo)
        #expect(album?.played == example.played)
    }
}
