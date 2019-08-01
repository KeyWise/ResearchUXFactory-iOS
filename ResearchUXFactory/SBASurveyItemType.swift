//
//  SBASurveyItemType.swift
//  ResearchUXFactory
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import ResearchKit

/**
 List of all the currently supported step types with the key name for each class type.
 This is used by the `SBABaseSurveyFactory` to determine which subclass of `ORKStep` to return
 for a given `SBASurveyItem`.
 */
public enum SBASurveyItemType {
    
    case custom(String?)
    
    case subtask                                        // SBASubtaskStep
    public static let subtaskKey = "subtask"
    
    case instruction(InstructionSubtype)
    public enum InstructionSubtype: String {
        case instruction        = "instruction"         // ORKInstructionStep
        case completion         = "completion"          // ORKCompletionStep
    }
    
    case form(FormSubtype)                              // ORKFormStep
    public enum FormSubtype: String {
        case compound           = "compound"            // ORKFormItems > 1
        case toggle             = "toggle"              // SBABooleanToggleFormStep
        case boolean            = "boolean"             // ORKBooleanAnswerFormat
        case singleChoice       = "singleChoiceText"    // ORKTextChoiceAnswerFormat of style SingleChoiceTextQuestion
        case multipleChoice     = "multipleChoiceText"  // ORKTextChoiceAnswerFormat of style MultipleChoiceTextQuestion
        case text               = "textfield"           // ORKTextAnswerFormat
        case multipleLineText   = "multilineText"       // ORKTextAnswerFormat with multiple lines
        case date               = "datePicker"          // ORKDateAnswerFormat of style Date
        case dateTime           = "timeAndDatePicker"   // ORKDateAnswerFormat of style DateTime
        case time               = "timePicker"          // ORKTimeOfDayAnswerFormat
        case duration           = "timeInterval"        // ORKTimeIntervalAnswerFormat
        case integer            = "numericInteger"      // ORKNumericAnswerFormat of style Integer
        case decimal            = "numericDecimal"      // ORKNumericAnswerFormat of style Decimal
        case scale              = "scaleInteger"        // ORKScaleAnswerFormat
        case continuousScale    = "continuousScale"     // ORKContinuousScaleAnswerFormat
        case timingRange        = "timingRange"         // Timing Range: ORKTextChoiceAnswerFormat of style SingleChoiceTextQuestion
    }
    
    case consent(ConsentSubtype)
    public enum ConsentSubtype: String {
        case sharingOptions     = "consentSharingOptions"   // ORKConsentSharingStep
        case review             = "consentReview"           // ORKConsentReviewStep
        case visual             = "consentVisual"           // ORKVisualConsentStep
    }
    
    case dataGroups(FormSubtype)                            // SBADataGroupsStep
    static let dataGroupsIdentifier = "dataGroups"
    
    case account(AccountSubtype)
    public enum AccountSubtype: String {
        case registration       = "registration"            // ORKRegistrationStep
        case login              = "login"                   // SBAProfileFormStep
        case emailVerification  = "emailVerification"       // Custom
        case externalID         = "externalID"              // SBAProfileFormStep
        case permissions        = "permissions"             // SBAPermissionsStep
        case profile            = "profile"                 // SBAProfileFormStep
    }
    
    case passcode(ORKPasscodeType)
    public enum PasscodeSubtype: String {
        case type6Digit         = "passcodeType6Digit"      // ORKPasscodeType6Digit
        case type4Digit         = "passcodeType4Digit"      // ORKPasscodeType4Digit
    }
    
    public init(rawValue: String?) {
        guard let type = rawValue else { self = .custom(nil); return }
        
        if let subtype = InstructionSubtype(rawValue: type) {
            self = .instruction(subtype)
        }
        else if let subtype = FormSubtype(rawValue: type) {
            self = .form(subtype)
        }
        else if type.hasPrefix(SBASurveyItemType.dataGroupsIdentifier) {
            let subtype: FormSubtype = {
                guard let subtypeString = type.parseSuffix(prefix: "\(SBASurveyItemType.dataGroupsIdentifier)."),
                    let subtype = FormSubtype(rawValue: subtypeString) else {
                        return .multipleChoice
                }
                return subtype
            }()
            self = .dataGroups(subtype)
        }
        else if let subtype = ConsentSubtype(rawValue: type) {
            self = .consent(subtype)
        }
        else if let subtype = AccountSubtype(rawValue: type) {
            self = .account(subtype)
        }
        else if let subtype = ORKPasscodeType(key: type) {
            self = .passcode(subtype)
        }
        else if type == SBASurveyItemType.subtaskKey {
            self = .subtask
        }
        else {
            self = .custom(type)
        }
    }
    
    public func formSubtype() -> FormSubtype? {
        if case .form(let subtype) = self {
            return subtype
        } else if case .dataGroups(let subtype) = self {
            return subtype
        }
        return nil
    }
    
    public func consentSubtype() -> ConsentSubtype? {
        if case .consent(let subtype) = self {
            return subtype
        }
        return nil
    }
    
    public func accountSubtype() -> AccountSubtype? {
        if case .account(let subtype) = self {
            return subtype
        }
        return nil
    }
    
    public func isNilType() -> Bool {
        if case .custom(let customType) = self {
            return (customType == nil)
        }
        return false
    }
    
    public var usesPlaceholderText: Bool {
        return self == SBASurveyItemType.form(.text) || self == SBASurveyItemType.form(.multipleLineText)
    }
}

extension SBASurveyItemType: Equatable {
}

public func ==(lhs: SBASurveyItemType, rhs: SBASurveyItemType) -> Bool {
    switch (lhs, rhs) {
    case (.instruction(let lhsValue), .instruction(let rhsValue)):
        return lhsValue == rhsValue;
    case (.form(let lhsValue), .form(let rhsValue)):
        return lhsValue == rhsValue;
    case (.consent(let lhsValue), .consent(let rhsValue)):
        return lhsValue == rhsValue;
    case (.account(let lhsValue), .account(let rhsValue)):
        return lhsValue == rhsValue;
    case (.passcode(let lhsValue), .passcode(let rhsValue)):
        return lhsValue == rhsValue;
    case (.subtask, .subtask):
        return true
    case (.custom(let lhsValue), .custom(let rhsValue)):
        return lhsValue == rhsValue;
    default:
        return false
    }
}

extension SBASurveyItemType: SBACustomTypeStep {
    public var customTypeIdentifier: String? {
        if case .custom(let type) = self {
            return type
        }
        return nil
    }
}

extension ORKPasscodeType {
    init?(key: String) {
        guard let type = SBASurveyItemType.PasscodeSubtype(rawValue: key) else {
            return nil
        }
        switch (type) {
        case .type6Digit:
            self = .type6Digit
        case .type4Digit:
            self = .type4Digit
        }
    }
}
