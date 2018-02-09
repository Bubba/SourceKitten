//
//  SourceKitObject.swift
//  SourceKitten
//
//  Created by Norio Nomura on 2/7/18.
//  Copyright © 2018 SourceKitten. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
import SourceKit
#endif

// MARK: - SourceKitObjectConvertible
public protocol SourceKitObjectConvertible {
    func sourceKitObject() throws -> sourcekitd_object_t
}

extension SourceKitObjectConvertible {
    func error(_ description: String) -> SourceKitObject.Error {
        return SourceKitObject.Error(description: description)
    }

    func failedToCreate() -> SourceKitObject.Error {
        return error( "Failed to create sourcekitd_object_t from: \(self)")
    }
}

extension Array: SourceKitObjectConvertible /* where Element: SourceKitObjectConvertible */ {
    public func sourceKitObject() throws -> sourcekitd_object_t {
        guard Element.self is SourceKitObjectConvertible.Type else {
            throw error("Array confirms to SourceKitObjectConvertible when `Elements` is `SourceKitObjectConvertible`!")
        }
        let objects: [sourcekitd_object_t?] = try map { try ($0 as! SourceKitObjectConvertible).sourceKitObject() }
        guard let object = sourcekitd_request_array_create(objects, objects.count) else { throw failedToCreate() }
        return object
    }
}

extension Array /* : SourceKitObjectConvertible */ where Element == (UID, SourceKitObjectConvertible) {
    public func sourceKitObject() throws -> sourcekitd_object_t {
        let keys: [sourcekitd_uid_t?] = map { $0.0.uid }
        let values: [sourcekitd_object_t?] = try map { try $0.1.sourceKitObject() }
        guard let object = sourcekitd_request_dictionary_create(keys, values, count) else { throw failedToCreate() }
        return object
    }
}

extension Dictionary: SourceKitObjectConvertible /* where Value: SourceKitObjectConvertible */ {
    public func sourceKitObject() throws -> sourcekitd_object_t {
        guard Value.self is SourceKitObjectConvertible.Type else {
            throw error("Dictionary confirms to SourceKitObjectConvertible when `Value` is `SourceKitObjectConvertible`!")
        }
        if Key.self is UID.Type {
            return try map { (($0.key as! UID), $0.value as! SourceKitObjectConvertible) }.sourceKitObject()
        } else if Key.self is String.Type {
            return try map { (UID($0.key as! String), $0.value as! SourceKitObjectConvertible) }.sourceKitObject()
        }
        throw error("Dictionary confirms to `SourceKitObjectConvertible` when `Key` is `UID` or `String`!")
    }
}

extension Int: SourceKitObjectConvertible {
    public func sourceKitObject() throws -> sourcekitd_object_t {
        return try Int64(self).sourceKitObject()
    }
}

extension Int64: SourceKitObjectConvertible {
    public func sourceKitObject() throws -> sourcekitd_object_t {
        guard let object = sourcekitd_request_int64_create(self)  else { throw failedToCreate() }
        return object
    }
}

extension String: SourceKitObjectConvertible {
    public func sourceKitObject() throws -> sourcekitd_object_t {
        guard let object = sourcekitd_request_string_create(self) else { throw failedToCreate() }
        return object
    }
}

// MARK: - SourceKitObject

/// Swift representation of sourcekitd_object_t
public class SourceKitObject: ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral, ExpressibleByIntegerLiteral, ExpressibleByStringLiteral {
    fileprivate var _sourceKitObject: sourcekitd_object_t

    public init(_ sourceKitObject: sourcekitd_object_t) {
        self._sourceKitObject = sourceKitObject
    }

    deinit {
        sourcekitd_request_release(_sourceKitObject)
    }

    public struct Error: Swift.Error {
        let description: String
    }

    /// Updates the value stored in the dictionary for the given key,
    /// or adds a new key-value pair if the key does not exist.
    ///
    /// - Parameters:
    ///   - value: The new value to add to the dictionary.
    ///   - key: The key to associate with value. If key already exists in the dictionary, 
    ///     value replaces the existing associated value. If key isn't already a key of the dictionary
    public func updateValue(_ value: SourceKitObjectConvertible, forKey key: UID) throws {
        sourcekitd_request_dictionary_set_value(_sourceKitObject, key.uid, try value.sourceKitObject())
    }

    public func updateValue(_ value: SourceKitObjectConvertible, forKey key: String) throws {
        try updateValue(value, forKey: UID(key))
    }

    public func updateValue<T>(_ value: SourceKitObjectConvertible, forKey key: T) throws where T: RawRepresentable, T.RawValue == String {
        try updateValue(value, forKey: UID(key.rawValue))
    }

    // ExpressibleByArrayLiteral
    public required init(arrayLiteral elements: SourceKitObject...) {
        do { _sourceKitObject = try elements.sourceKitObject() } catch { fatalError("\(error)") }
    }

    // ExpressibleByDictionaryLiteral
    public required init(dictionaryLiteral elements: (UID, SourceKitObjectConvertible)...) {
        do { _sourceKitObject = try elements.sourceKitObject() } catch { fatalError("\(error)") }
    }

    // ExpressibleByIntegerLiteral
    public required init(integerLiteral value: IntegerLiteralType) {
        do { _sourceKitObject = try value.sourceKitObject() } catch { fatalError("\(error)") }
    }

    // ExpressibleByStringLiteral
    public required init(stringLiteral value: StringLiteralType) {
        do { _sourceKitObject = try value.sourceKitObject() } catch { fatalError("\(error)") }
    }
}

extension SourceKitObject: SourceKitObjectConvertible {
    public func sourceKitObject() throws -> sourcekitd_object_t {
        return _sourceKitObject
    }
}

extension SourceKitObject: CustomStringConvertible {
    public var description: String {
        let bytes = sourcekitd_request_description_copy(_sourceKitObject)!
        let length = Int(strlen(bytes))
        return String(bytesNoCopy: bytes, length: length, encoding: .utf8, freeWhenDone: true)!
    }
}
