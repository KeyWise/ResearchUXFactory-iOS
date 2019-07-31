//
//  ORKStep+ResultsExtension.swift
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
 Methods for returning a default result for a given type of `ORKStep`. This is used in 
 unit testing and for data tracking.
 */
extension ORKStep {
    
    @objc
    open func defaultStepResult() -> ORKStepResult {
        return stepResult(with: nil, shouldSetDefault: true)
    }
    
    @objc(stepResultWithAnswerMap:)
    public func stepResult(with answerMap: [String: Any]?) -> ORKStepResult {
        return self.stepResult(with: answerMap, shouldSetDefault: false)
    }
    
    @objc(stepResultWithAnswerMap:shouldSetDefault:)
    open func stepResult(with answerMap: [String: Any]?, shouldSetDefault:Bool) -> ORKStepResult {
        return ORKStepResult(stepIdentifier: self.identifier, results: nil)
    }
}

extension ORKFormStep {
    override open func stepResult(with answerMap: [String: Any]?, shouldSetDefault:Bool) -> ORKStepResult {
        let stepResult = super.stepResult(with: answerMap, shouldSetDefault: shouldSetDefault)
        stepResult.results = self.formItems?.sba_mapAndFilter({ (formItem) -> ORKResult? in
            let answer = answerMap?[formItem.identifier]
            guard answer != nil || shouldSetDefault else { return nil }
            return formItem.questionResult(identifier: formItem.identifier, answer: answer)
        })
        return stepResult
    }
}

extension ORKQuestionStep {
    override open func stepResult(with answerMap: [String: Any]?, shouldSetDefault:Bool) -> ORKStepResult {
        let stepResult = super.stepResult(with: answerMap, shouldSetDefault: shouldSetDefault)
        if let answerFormat = self.answerFormat as? SBAQuestionResultMapping {
            let answer = answerMap?[self.identifier]
            if answer != nil || shouldSetDefault,
                let questionResult = answerFormat.questionResult(identifier: self.identifier, answer: answer) {
                stepResult.results = [questionResult]
            }
        }
        return stepResult
    }
}

public protocol SBAQuestionResultMapping {
    var questionType: ORKQuestionType { get }
    func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult?
}

extension ORKFormItem: SBAQuestionResultMapping {
    
    public var questionType: ORKQuestionType {
        return self.answerFormat?.questionType ?? .none
    }
    
    // Convenience method for adding a default answer or mapped answer for a given form item
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        guard let answerFormat = self.answerFormat as? SBAQuestionResultMapping,
            let questionResult = answerFormat.questionResult(identifier: identifier, answer: answer)
            else {
                assertionFailure("Unsupported answer format \(String(describing: self.answerFormat))")
                return nil
        }
        questionResult.questionType = answerFormat.questionType
        return questionResult
    }
}

extension ORKTextChoiceAnswerFormat: SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        // Exit early if there are no choices
        guard self.textChoices.count > 0 else { return nil }
        
        // Check that the answer is formatted as an array
        var choiceAnswers = answer as? [AnyObject]
        if choiceAnswers == nil && answer != nil {
            choiceAnswers = [answer! as AnyObject]
        }
        
        // Check that the choice answers are nil or valid
        guard (choiceAnswers == nil) || isValidAnswer(choiceAnswers! as AnyObject) else {
            assertionFailure("\(String(describing: answer)) is invalid")
            return nil
        }
        
        let result = ORKChoiceQuestionResult(identifier: identifier)
        if choiceAnswers != nil {
            result.choiceAnswers = choiceAnswers
        }
        else {
            result.choiceAnswers = [self.textChoices.last!.value]
        }
        
        return result
    }
    
    func isValidAnswer(_ answer: AnyObject) -> Bool {
        guard let choiceAnswers = answer as? [NSObject] else {
            return false
        }
        let filteredChoices = self.textChoices.filter ({ (textChoice) -> Bool in
            guard let value = textChoice.value as? NSObject else { return false }
            return choiceAnswers.contains(value)
        })
        return filteredChoices.count == choiceAnswers.count
    }
}

extension ORKScaleAnswerFormat : SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        let result = ORKScaleQuestionResult(identifier: identifier)
        if let num = answer as? NSNumber {
            result.scaleAnswer = num
        }
        else {
            result.scaleAnswer = (self.defaultValue as NSNumber?)
        }
        
        return result
    }
}

extension ORKBooleanAnswerFormat : SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        let result = ORKBooleanQuestionResult(identifier: identifier)
        if let num = answer as? NSNumber {
            result.booleanAnswer = num
        }
        else {
            result.booleanAnswer = false
        }
        
        return result
    }
}

extension ORKHealthKitQuantityTypeAnswerFormat : SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        let result = ORKNumericQuestionResult(identifier: identifier)
        if let num = answer as? NSNumber {
            result.numericAnswer = num
        }
        else if let qty = answer as? HKQuantity, let unit = self.unit {
            result.numericAnswer = NSNumber(value: qty.doubleValue(for: unit))
            result.unit = unit.unitString
        }
        
        return result
    }
}

extension ORKNumericAnswerFormat : SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        let result = ORKNumericQuestionResult(identifier: identifier)
        if let num = answer as? NSNumber {
            result.numericAnswer = num
            result.unit = self.unit
        }
        
        return result
    }
}

extension ORKTextAnswerFormat : SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        let result = ORKTextQuestionResult(identifier: identifier)
        if let text = answer as? String {
            result.textAnswer = text
        }
        
        return result
    }
}

extension ORKEmailAnswerFormat : SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        let result = ORKTextQuestionResult(identifier: identifier)
        if let text = answer as? String {
            result.textAnswer = text
        }
        
        return result
    }
}

extension ORKDateAnswerFormat : SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        let result = ORKDateQuestionResult(identifier: identifier)
        if let date = answer as? Date {
            result.dateAnswer = date
        }
        else if let dateString = answer as? String {
            result.dateAnswer = NSDate(iso8601String: dateString) as Date?
        }
        
        return result
    }
}

extension ORKHealthKitCharacteristicTypeAnswerFormat: SBAQuestionResultMapping {
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        
        guard let answerFormat = self.implied() as? SBAQuestionResultMapping
            else {
                assertionFailure("Unsupported answer format \(String(describing: self.implied()))")
                return nil
        }

        return answerFormat.questionResult(identifier: identifier, answer: answer)
        
    }
}

extension ORKMoodScaleAnswerFormat : SBAQuestionResultMapping {
    
    public func questionResult(identifier: String, answer: Any?) -> ORKQuestionResult? {
        if let num = answer as? NSNumber {
            let result = ORKMoodScaleQuestionResult(identifier: identifier)
            result.scaleAnswer = num
            return result
        }
        else if let selected = answer as? [AnyObject] {
            let result = ORKChoiceQuestionResult(identifier: identifier)
            result.choiceAnswers = selected
            return result
        }
        else if answer != nil {
            let result = ORKChoiceQuestionResult(identifier: identifier)
            result.choiceAnswers = [answer!]
            return result
        }
        return ORKMoodScaleQuestionResult(identifier: identifier)
    }
}

