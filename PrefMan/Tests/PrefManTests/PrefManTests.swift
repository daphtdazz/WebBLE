import PrefMan
import PrefManMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

let justPrefMan: [String: Macro.Type] = [
    "PrefMan": PrefManMacro.self
]

final class PrefManTests: XCTestCase {

    func testPrefManMacroDefaultExpansion() throws {
        assertPrefManMacroEffect(
            """
            var lastLocation: URL = URL(string: "https://gps.com")!
            """,
            """
            var lastLocation: URL {
                get {
                    let optVal = URL(string: _dict["lastLocation"] as? String ?? "")
                    let udVal = optVal ?? URL(string: "https://gps.com")!
                    return udVal
                }
                set {
                    save(value: newValue.absoluteString, forKey: "lastLocation")
                }
            }

            override open func dataRepresentation() -> UDDictType {
                var repr: UDDictType = [:]
                repr["lastLocation"] = lastLocation.absoluteString as Any
                return repr
            }
            """
        )
    }
    func testPrefManMacroOptionalExpansion() throws {
        assertPrefManMacroEffect(
            """
            var maybeString: String?
            """,
            """
            var maybeString: String? {
                get {
                    let optVal = _dict["maybeString"] as? String
                    let udVal = optVal
                    return udVal
                }
                set {
                    save(value: newValue, forKey: "maybeString")
                }
            }

            override open func dataRepresentation() -> UDDictType {
                var repr: UDDictType = [:]
                if let _local_maybeString = maybeString {
                    repr["maybeString"] = _local_maybeString as Any
                }
                return repr
            }
            """
        )
    }
    func testPrefManMacroOptionalArrayChild() throws {
        assertPrefManMacroEffect(
            """
            var children: PrefManArray<AnotherPrefMan>?
            """,
            """
            var children: PrefManArray<AnotherPrefMan>? {
                get {
                    _childrenBackingArray
                }
                set {
                    if let existingArray = _childrenBackingArray {
                        _removeChildLinks(existingArray)
                    }
                    _childrenBackingArray = newValue
                    if let newValueHard = newValue {
                        _addChildLinks(newValueHard, forKey: "children")
                    }
                }
            }

            private var _childrenBackingArray: PrefManArray<AnotherPrefMan>? = nil

            override func buildChildren() {
                if let _local_children = _dict["children"] as? UDArrayType {
                    _childrenBackingArray = PrefManArray<AnotherPrefMan>(
                        parent: self, initial: _local_children
                    )
                    _addChildLinks(_childrenBackingArray!, forKey: "children")
                }
            }
            """,
        )
    }
    func testPrefManMacroArrayChild() throws {
        assertPrefManMacroEffect(
            """
            var children: PrefManArray<AnotherPrefMan>

            let childrenDefault: UDArrayType = []
            """,
            """
            var children: PrefManArray<AnotherPrefMan> {
                get {
                    if let value = _childrenBackingArray {
                        return value
                    }
                    let defaultValue = PrefManArray<AnotherPrefMan>(parent: self, initial: childrenDefault)!
                    self.children = defaultValue
                    return defaultValue
                }
                set {
                    if let existingArray = _childrenBackingArray {
                        _removeChildLinks(existingArray)
                    }
                    _childrenBackingArray = newValue
                    _addChildLinks(newValue, forKey: "children")
                }
            }

            private var _childrenBackingArray: PrefManArray<AnotherPrefMan>? = nil

            let childrenDefault: UDArrayType = []

            override func buildChildren() {
                if let _local_children = _dict["children"] as? UDArrayType {
                    _childrenBackingArray = PrefManArray<AnotherPrefMan>(
                        parent: self, initial: _local_children
                    )
                    _addChildLinks(_childrenBackingArray!, forKey: "children")
                }
            }
            """,
        )
    }

    func testPrefManMacroIgnoresAlreadyComputed() throws {
        assertPrefManMacroNoEffect(
            """
            var alreadyAccessed {
                get { "testvalue" }
            }
            """
        )
    }

    func testPrefManMacroIgnoresFunction() throws {
        assertPrefManMacroNoEffect(
            """
            func someFunc() {
                // unaffected
            }
            """
        )
    }

    func testPrefManMacroIgnoresIgnored() throws {
        assertPrefManMacroEffect(
            """
            @PrefManIgnore
            var toBeIgnored: String? = nil
            """,
            """
            var toBeIgnored: String? = nil
            """
        )
    }

    func testPrefManUnrecognisedType() throws {
        assertPrefManMacroDiagnostics(
            "var someType: SomeType?",
            [
                DiagnosticSpec(
                    message: "Unusable type \"SomeType?\" for PrefMan",
                    line: 3,
                    column: 19
                )
            ]
        )
    }
    func testPrefManUnrecognisedArrayType() throws {
        assertPrefManMacroDiagnostics(
            "var someType: [SomeType]",
            [
                DiagnosticSpec(
                    message: "Unusable type \"[SomeType]\" for PrefMan",
                    line: 3,
                    column: 19
                )
            ]
        )
    }

    func testPrefManMacroDiagnostics() throws {
        assertMacroExpansion(
            // deliberate indent to check diagnostc column matches
            """
              @PrefMan
            enum MyClass {
                var lastLocation: URL
            }
            """,
            expandedSource: """
                enum MyClass {
                    var lastLocation: URL
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@PrefManMacro can only be applied to a class",
                    line: 1,
                    column: 3
                )
            ],
            macros: justPrefMan
        )
    }

    func testPrefManMissingInitializer() throws {
        assertPrefManMacroDiagnostics(
            "var someString: String",
            [
                DiagnosticSpec(
                    message: "Non-optional @PrefManAttr property needs an initializer",
                    line: 3,
                    column: 5
                )
            ]
        )
    }
}

@PrefMan
class ChildPrefMan: PrefMan {
    public var someChildValue: String?
    public var someUrl: URL? = nil

    override class var upgrades: PrefMan.PrefManUpgraderSet {
        [
            1: [
                {
                    dict in
                    if let someChildValue = dict["someChildValue"] as? String {
                        dict["someChildValue"] = "\(someChildValue) - upgraded"
                    } else {
                        dict.removeValue(forKey: "someChildValue")
                    }
                }
            ],
            2: [
                {
                    dict in
                    if let someCV = dict["someChildValue"] as? String {
                        dict["someUrl"] = someCV
                    }
                }
            ],
        ]
    }
}

@PrefMan
class ExamplePrefMan: PrefMan {
    var someNumber: Int = 2

    var children: PrefManArray<ChildPrefMan>?
    var childrenWithDefault: PrefManArray<ChildPrefMan>

    let childrenWithDefaultDefault: UDArrayType = [
        ["someChildValue": "hello, bob"],
        ["someChildValue": "hello, caro"],
    ]

    override class var upgrades: PrefMan.PrefManUpgraderSet {
        [
            1: [
                {
                    dict in
                    if let someNum = dict["someNumber"] as? Int {
                        dict["someNumber"] = (someNum * 2) as Any
                    } else {
                        dict.removeValue(forKey: "someNumber")
                    }
                }
            ]
        ]
    }
}

final class PrefManChildManagerTest: XCTestCase {
    func testChildManager() throws {
        let epm = ExamplePrefMan(defaults: UserDefaults.cleanUDForTests())

        XCTAssertNil(epm.children)

        epm.children = PrefManArray<ChildPrefMan>(array: [], parent: epm)

        let child = try epm.children!.newItem(initial: [:])
        child.someChildValue = "hello world"

        let epm2 = ExamplePrefMan(defaults: epm.userDefaults!)

        XCTAssertEqual(epm2.children?[0].someChildValue, "hello world")
    }

    func testChildOptionalArray() throws {
        let epm = ExamplePrefMan(defaults: UserDefaults.cleanUDForTests())

        XCTAssertNotNil(epm.childrenWithDefaultDefault)
        XCTAssertEqual(epm.childrenWithDefault.count, 2)
        XCTAssertEqual(epm.childrenWithDefault[0].someChildValue, "hello, bob")
    }

    func testMoveDefaultArrayEntry() throws {
        let epm = ExamplePrefMan(defaults: UserDefaults.cleanUDForTests())

        epm.childrenWithDefault.move(from: 1, to: 0)

        let epm2 = ExamplePrefMan(defaults: epm.userDefaults!)
        XCTAssertEqual(epm2.childrenWithDefault[0].someChildValue, "hello, caro")
    }
}

final class PrefManUpgradeTests: XCTestCase {
    func testPrefManUpgradesIgnoresDefaults() throws {
        let epm = ExamplePrefMan(defaults: UserDefaults.cleanUDForTests())
        XCTAssertEqual(epm.someNumber, 2)

        epm.upgrade()
        // not changed because someNumber was never set, so the default is used
        XCTAssertEqual(epm.someNumber, 2)
    }
    func testPrefManUpgrades() throws {
        let ud = UserDefaults.cleanUDForTests()
        ud.set([], forKey: "children")
        let epm = ExamplePrefMan(defaults: ud)
        XCTAssertEqual(epm.userDefaults!.integer(forKey: "_prefVersion"), 0)

        epm.someNumber = 2
        let child = try epm.children!.newItem(initial: ["someUrl": "about:blank"])
        child.someChildValue = "hello"

        epm.upgrade()
        XCTAssertEqual(epm.someNumber, 4)
        XCTAssertEqual(epm.userDefaults!.integer(forKey: "_prefVersion"), 1)
        XCTAssertEqual(
            (epm.userDefaults!.array(forKey: "children")! as! [[String: Any]])[0]["someChildValue"]!
                as! String,
            "hello - upgraded"
        )
        XCTAssertEqual(
            epm.children![0].someUrl?.absoluteString,
            "hello%20-%20upgraded"
        )

        // Another upgrade is no-op
        epm.upgrade()
        XCTAssertEqual(epm.someNumber, 4)
    }
}
