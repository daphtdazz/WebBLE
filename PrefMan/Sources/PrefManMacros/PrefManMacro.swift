import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

// MARK: - Diagnostics
enum PrefManDiagnosticMessage: DiagnosticMessage {
    case classOnly
    case needsExplicitType
    case unusableType(String)
    case missingNonOptionalInitializer

    var severity: DiagnosticSeverity { return .error }
    var message: String {
        switch self {
        case .classOnly:
            "@PrefManMacro can only be applied to a class"
        case .needsExplicitType:
            "@PrefMan property needs an explicit type"
        case .unusableType(let name):
            "Unusable type \"\(name)\" for PrefMan"
        case .missingNonOptionalInitializer:
            "Non-optional @PrefManAttr property needs an initializer"
        }
    }
    var id: String {
        switch self {
        case .classOnly: "classOnly"
        case .needsExplicitType: "needsExplicitType"
        case .unusableType(_): "unusableType"
        case .missingNonOptionalInitializer: "missingNonOptionalInitializer"
        }
    }
    var diagnosticID: SwiftDiagnostics.MessageID {
        MessageID(domain: "PrefManMacro", id: id)

    }

    static func diagUnusableType(_ node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: node, message: Self.unusableType(node.description))
    }
    static func diagNeedsExplicitType(_ node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: node, message: Self.needsExplicitType)
    }
    static func diagMissingNonOptionalInitializer(_ node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: node, message: Self.missingNonOptionalInitializer)
    }
}

// MARK: - PrefManMacro
public struct PrefManMacro: MemberAttributeMacro, PeerMacro, MemberMacro {

    struct ParentDeclInfo {
        let allPropertyNames: [String]
        let prefManPropertyNames: [String]
        let membersNamesToIgnore: [String]
    }

    static func verifyParentDecl(
        _ declaration: some DeclSyntaxProtocol,
        context: some MacroExpansionContext? = (nil as BasicMacroExpansionContext?)
    ) -> ParentDeclInfo? {
        guard let classDecl = declaration.as(ClassDeclSyntax.self)
        else {
            context?.diagnose(
                Diagnostic(
                    node: declaration,
                    message: PrefManDiagnosticMessage.classOnly
                )
            )
            return nil
        }

        var allDeclNames: [String] = []
        var propertyNames: [String] = []
        var membersNamesToIgnore: [String] = []

        for member in classDecl.memberBlock.members {
            guard
                let vdecl = member.decl.as(VariableDeclSyntax.self),
                let propName = vdecl.firstDeclName
            else {
                continue
            }
            allDeclNames.append(propName)
            guard let vdeclInfo = verifyDecl(member.decl) else {
                continue
            }
            propertyNames.append(vdeclInfo.propertyName)
            membersNamesToIgnore.append(vdeclInfo.defaultPropertyName)
        }

        return ParentDeclInfo(
            allPropertyNames: allDeclNames,
            prefManPropertyNames: propertyNames,
            membersNamesToIgnore: membersNamesToIgnore,
        )
    }

    // MARK: Member attributes
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard let parentInfo = Self.verifyParentDecl(declaration) else {
            return []
        }

        guard
            let vdeclInfo = verifyDecl(member, context: context),
            !parentInfo.membersNamesToIgnore.contains(vdeclInfo.propertyName),
            !vdeclInfo.vdecl.hasAny(attrs: ["PrefManIgnore", "PrefManAttr"])
        else {
            // Only modify variable declarations that aren't already attributed
            return []
        }
        return [
            "@PrefManAttr"
        ]
    }

    // MARK: Peers
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let _ = Self.verifyParentDecl(declaration, context: context) else {
            return []
        }

        return []
    }

    // MARK: Members
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let parentInfo = Self.verifyParentDecl(declaration) else {
            return []
        }
        // collect array and manager children
        // TODO: implement dictionary children
        var arrayChildren: [PrefManItemDeclInfo] = []
        var dataChildren: [PrefManItemDeclInfo] = []

        for member in declaration.memberBlock.members {
            guard
                let vdecl = member.decl.as(VariableDeclSyntax.self)
                    else {
                continue
            }
            guard let declInfo = verifyDecl(vdecl) else {
                continue
            }
            guard !parentInfo.membersNamesToIgnore.contains(declInfo.propertyName) else {
                continue
            }
            if declInfo.isPrefManArray {
                arrayChildren.append(declInfo)
            } else {
                dataChildren.append(declInfo)
            }
        }

        var decls: [DeclSyntax] = []

        // dataRepresentation
        if dataChildren.count > 0 {
            let dataRepresentation = try FunctionDeclSyntax(
                "override open func dataRepresentation() -> UDDictType"
            ) {
                "var repr: UDDictType = [:]"
                for dataDecl in dataChildren {
                    let dataExpr = dataDecl.dataExpr(from: "\(raw: dataDecl.propertyName)")
                    let propNameExpr = dataDecl.propertyName.makeLiteralSyntax()
                    let localNameExpr: ExprSyntax = "_local_\(raw: dataDecl.propertyName)"
                    if !dataDecl.isOptional {
                        """
                        repr[\(propNameExpr)] = \(dataExpr) as Any
                        """
                    } else {
                        """
                        if let \(localNameExpr) = \(dataExpr) {
                            repr[\(propNameExpr)] = \(localNameExpr) as Any
                        }
                        """
                    }
                }
                "return repr"
            }
            decls.append(DeclSyntax(dataRepresentation))
        }

        // buildChildren
        if arrayChildren.count > 0 {
            let buildChildren = try FunctionDeclSyntax("override func buildChildren()") {
                for arrayDecl in arrayChildren {
                    let localName = TokenSyntax.identifier("_local_\(arrayDecl.propertyName)")
                    let propStringLiteral = arrayDecl.propertyName.makeLiteralSyntax()
                    """
                    if let \(localName) = _dict[\(propStringLiteral)] as? UDArrayType {
                        \(arrayDecl.backingArrayToken) = \(arrayDecl.typeIdentifier)(
                            parent: self, initial: \(localName)
                        )
                        _addChildLinks(\(arrayDecl.backingArrayToken)!, forKey: \(arrayDecl.propertyNameStringLiteral))
                    }
                    """
                }
            }
            decls.append(DeclSyntax(buildChildren))
        }
        return decls
    }
}

// MARK: - PrefManAttr attribute handling

public struct PrefManAttr: AccessorMacro, PeerMacro {
    // MARK: Peers
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let declInfo = verifyDecl(declaration) else {
            return []
        }
        guard declInfo.isPrefManArray else {
            return []
        }

        return [
            "private var \(declInfo.backingArrayToken): \(declInfo.typeIdentifier)? = nil",
        ]
    }

    // MARK: Accessors
    private static func _expandPrefManArrayAccessors(
        _ declInfo: PrefManItemDeclInfo,
    ) throws -> [AccessorDeclSyntax] {
        [
            try AccessorDeclSyntax("get") {
                if declInfo.isOptional {
                    "\(declInfo.backingArrayToken)"
                } else {
                    """
                    if let value = \(declInfo.backingArrayToken) {
                        return value
                    }
                    """
                    """
                    let defaultValue = \(declInfo.typeIdentifier)(\
                    parent: self, initial: \(raw: declInfo.defaultPropertyName))!
                    """
                    "self.\(raw: declInfo.propertyName) = defaultValue"
                    "return defaultValue"
                }
            },
            try AccessorDeclSyntax("set") {
                """
                if let existingArray = \(declInfo.backingArrayToken) {
                    _removeChildLinks(existingArray) 
                }
                """
                "\(declInfo.backingArrayToken) = newValue"
                if declInfo.isOptional {
                    """
                    if let newValueHard = newValue {
                        _addChildLinks(newValueHard, forKey: \(declInfo.propertyNameStringLiteral))
                    }
                    """
                } else {
                    """
                    _addChildLinks(newValue, forKey: \(declInfo.propertyNameStringLiteral))
                    """
                }
            },
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        /// Only modify variable declarations that don't already have accessors, have types and
        /// haven't explicitly been ignored
        guard let declInfo = verifyDecl(declaration)
        else {
            return []
        }

        if declInfo.isPrefManArray {
            return try _expandPrefManArrayAccessors(declInfo)
        }

        let initializerExpr = declInfo.binding.initializer?.value
        if initializerExpr == nil && !declInfo.isOptional {
            context.diagnose(
                Diagnostic(
                    node: declaration,
                    message: PrefManDiagnosticMessage.missingNonOptionalInitializer
                )
            )
            return []
        }

        let keyLiteral = declInfo.propertyName.makeLiteralSyntax()

        let setter = try AccessorDeclSyntax("set") {
            let newValueDataExpr = declInfo.dataExpr(from: "newValue")
            "save(value: \(newValueDataExpr), forKey: \(keyLiteral))"
        }

        let optExpression = switch(declInfo.typeName) {
        case "URL":
            "URL(string: _dict[\(keyLiteral)] as? String ?? \"\")" as ExprSyntax
        default:
            "_dict[\(keyLiteral)] as? \(declInfo.typeIdentifier)" as ExprSyntax
        }

        let getter = try AccessorDeclSyntax("get") {
            "let optVal = \(optExpression)"
            if declInfo.isOptional {
                "let udVal = optVal"
            } else {
                // initializerExpr must at this point be set
                "let udVal = optVal ?? \(initializerExpr!)"
            }
            "return udVal"
        }
        return [getter, setter]
    }
}

public struct PrefManIgnore: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return []
    }
}

enum PrefManMacroInternalDiagnostic: DiagnosticMessage {
    case functionOnly

    var severity: DiagnosticSeverity { return .error }
    var message: String {
        switch self {
        case .functionOnly:
            return "only appliable to a function"
        }
    }
    var id: String {
        switch self {
        case .functionOnly: "functionOnly"
        }
    }
    var diagnosticID: SwiftDiagnostics.MessageID {
        MessageID(domain: "PrefManMacroInternal", id: id)
    }
}

@main
struct PrefManPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PrefManMacro.self,
        PrefManAttr.self,
        PrefManIgnore.self,
    ]
}
