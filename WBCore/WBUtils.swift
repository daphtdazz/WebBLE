//
//  WBUtils.swift
//  WebBLE
//
//  Created by David Park on 23/10/2026.
//
import Foundation

public extension UUID {

    func combineV4(_ other: UUID) -> UUID {
        // Bit layout of UUIDV4. All random except ver which is 0100 and var 10
        // https://www.rfc-editor.org/rfc/rfc9562.html#name-uuid-version-4
        //  0                   1                   2                   3
        //  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
        // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        // |                           random_a                            |
        // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        // |          random_a             |  ver  |       random_b        |
        // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        // |var|                       random_c                            |
        // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        // |                           random_c                            |
        // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        return UUID(uuid: (
            self.uuid.0 ^ other.uuid.0,
            self.uuid.1 ^ other.uuid.1,
            self.uuid.2 ^ other.uuid.2,
            self.uuid.3 ^ other.uuid.3,
            self.uuid.4 ^ other.uuid.4,
            self.uuid.5 ^ other.uuid.5,
            0b01000000 | (0b00001111 & (self.uuid.6 ^ other.uuid.6)), // v4 ver
            self.uuid.7 ^ other.uuid.7,
            0b10000000 | (0b00111111 & (self.uuid.8 ^ other.uuid.8)), // var
            self.uuid.9 ^ other.uuid.9,
            self.uuid.10 ^ other.uuid.10,
            self.uuid.11 ^ other.uuid.11,
            self.uuid.12 ^ other.uuid.12,
            self.uuid.13 ^ other.uuid.13,
            self.uuid.14 ^ other.uuid.14,
            self.uuid.15 ^ other.uuid.15,
       ))
    }
}
