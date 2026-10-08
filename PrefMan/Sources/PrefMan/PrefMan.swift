// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

// MARK: - Macros

// FYI there is an interesting bug see
// https://github.com/swiftlang/swift/issues/88877
// where you can't use the same name for a member and accessor macro. However
// we need different ones for the properties and the class as they are both
// peer macros.
@attached(memberAttribute)
@attached(peer)
@attached(member, names: named(buildChildren), named(dataRepresentation))
public macro PrefMan() = #externalMacro(module: "PrefManMacros", type: "PrefManMacro")

@attached(accessor)
@attached(peer, names: arbitrary)
public macro PrefManAttr() = #externalMacro(module: "PrefManMacros", type: "PrefManAttr")

// You can't have accessor macros that are just there to mark and return []
// (unless you are ObservationIgnored for some reason see
// github.com/swiftlang/swift/blame/main/lib/Macros/Sources/ObservationMacros/ObservableMacro.swift
// ), so make this a peer macro.
@attached(peer)
public macro PrefManIgnore() = #externalMacro(
    module: "PrefManMacros", type: "PrefManIgnore"
)

// MARK: - Types

public typealias UDArrayType = [Any]
public typealias UDDictType = [String: Any]

public enum PrefManError: Error {
    case invalidInitialType(String)
}

open class PrefManItemType: NSObject {
    // _parent is only not set in the root
    private let _parent: PrefManItemProtocol?
    public var parent: PrefManItemProtocol? { _parent }

    public init(parent: PrefManItemProtocol? = nil) {
        self._parent = parent
    }
}
// this shouldn't be public...
public protocol PrefManItemProtocol: NSObject, AnyObject {
    init?(parent: PrefManItemProtocol, initial: Any)
    var parent: PrefManItemProtocol? { get }
    var udRepresentation: Any { get }
    func saveChild(_: PrefManItemProtocol)
    func upgrade()
}

open class PrefManArray<T: PrefManItemProtocol>:
    PrefManItemType, Collection, PrefManItemProtocol
{
    // MARK: API
    public required init(array: UDArrayType, parent: PrefManItemProtocol) {
        super.init(parent: parent)
        _array = array.compactMap{ T(parent: self, initial: $0) }
    }

    public func newItem(at: Int, initial: Any) throws -> T {
        guard let newItem = T(parent: self, initial: initial) else {
            throw PrefManError.invalidInitialType(
                (initial as? CustomStringConvertible)?.description ?? "<unknown type>"
            )
        }
        _array.insert(newItem, at: at)
        return newItem
    }
    public func newItem(initial: Any) throws -> T {
        try newItem(at: _array.count, initial: initial)
    }
    public func move(from: Int, to: Int) {
        _array.insert(_array.remove(at: from), at: to)
        parent?.saveChild(self)
    }
    public func remove(at: Int) {
        _array.remove(at: at)
        parent?.saveChild(self)
    }

    // MARK: Collection conformance
    private var _array: [T] = []
    public func index(after i: Int) -> Int {
        _array.index(after: i)
    }
    public subscript(position: Int) -> T {
        get {
            _array[position]
        }
    }
    public var startIndex: Int { 0 }
    public var endIndex: Int { _array.count }

    // MARK: PrefManItemProtocol conformance
    public required convenience init?(parent: PrefManItemProtocol, initial: Any) {
        // if the object is not
        guard let array = initial as? UDArrayType else {
            return nil
        }
        self.init(array: array, parent: parent)
    }

    public func saveChild(_ child: any PrefManItemProtocol) {
        parent!.saveChild(self)
    }

    public var udRepresentation: Any {
        _array.map{ $0.udRepresentation }
    }

    public func upgrade() {
        _array.forEach{ $0.upgrade() }
    }
}


//@MainActor
open class PrefMan: PrefManItemType, PrefManItemProtocol {

    // User defaults is only set in the root
    public let userDefaults: UserDefaults?

    static internal let versionKey = "_prefVersion"

    public typealias PrefManUpgrader = (inout UDDictType) -> Void
    public typealias PrefManUpgraderSet = [Int: [PrefManUpgrader]]
    open class var upgrades: PrefManUpgraderSet { [:] }

    public init(defaults: UserDefaults) {
        _dict = defaults.dictionaryRepresentation()
        self.userDefaults = defaults
        super.init()
        self.buildChildren()
    }

    public required init(parent: PrefManItemProtocol, initial: UDDictType) {
        _dict = initial
        userDefaults = nil
        super.init(parent: parent)
        self.buildChildren()
    }

    public required convenience init?(
        parent: any PrefManItemProtocol, initial: Any
    ) {
        guard let initialDict = initial as? UDDictType else {
            return nil
        }
        self.init(parent: parent, initial: initialDict)
    }
    public convenience init() {
        self.init(defaults: UserDefaults.standard)
    }

    public func upgrade() {
        for child in _childKeyToManager.values {
            child.upgrade()
        }

        guard let latestVersion = Self.upgrades.keys.max() else {
            return
        }
        let currentVersion = _dict[Self.versionKey] as? Int ?? 0
        for ii in currentVersion+1..<latestVersion+1 {
            Self.upgrades[ii]!.forEach{ $0(&_dict) }
            save(value: ii, forKey: Self.versionKey)
        }
    }

    open var _dict: UDDictType
    open func buildChildren() {
        // Null-op: if subclasses have children to build the PrefMan macro
        // will override this
    }
    open func dataRepresentation() -> UDDictType {
        // No data by default: if subclasses have data properties the PrefMan
        // macro will override this
        return [:]
    }

    public func save(value: Any?, forKey key: String) {
        _dict[key] = value
        if parent == nil {
            userDefaults!.setValue(value, forKey: key)
        } else {
            parent!.saveChild(self)
        }
    }

    public func saveChild(_ child: any PrefManItemProtocol) {
        guard parent == nil else {
            parent?.saveChild(self)
            return
        }
        let key = _childObjectIdToKey[ObjectIdentifier(child)]!
        userDefaults!.set(child.udRepresentation, forKey: key)
    }

    public var udRepresentation: Any {
        var repr = dataRepresentation()
        for (key, child) in _childKeyToManager {
            repr[key] = child.udRepresentation
        }
        return repr
    }

    // MARK: Internals
    public var _childKeyToManager: [String: PrefManItemProtocol] = [:]
    public var _childObjectIdToKey: [ObjectIdentifier: String] = [:]
    public func _removeChildLinks(_ child: PrefManItemProtocol) {
        let key = _childObjectIdToKey.removeValue(forKey: ObjectIdentifier(child))!
        _childKeyToManager.removeValue(forKey: key)

    }
    public func _addChildLinks(_ child: PrefManItemProtocol, forKey key: String) {
        _childObjectIdToKey[ObjectIdentifier(child)] = key
        _childKeyToManager[key] = child

    }
}
