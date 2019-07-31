//
//  SBADataObjectCollection.swift
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

open class SBATrackedDataObjectCollection: SBADataObject, SBABridgeTask, SBAStepTransformer, SBAConditionalRule {
    

    lazy open var dataStore: SBATrackedDataStore! = {
        return SBATrackedDataStore.shared
    }()
    
    // MARK: Dynamic properties 
    
    @objc lazy open dynamic var taskIdentifier: String! = {
        return UUID().uuidString
    }()
    
    @objc lazy open dynamic var schemaIdentifier: String! = {
        return self.taskIdentifier
    }()
    
    @objc open dynamic var alwaysIncludeActivitySteps: Bool = false
    
    @objc open dynamic var itemsClassType: String!
    
    @objc open dynamic var items: [SBATrackedDataObject]!
    
    @objc open dynamic var steps: [Any]!
    
    @objc open dynamic var insertAfter: String?

    @objc open dynamic var trackingSurveyRepeatTimeInterval: TimeInterval = 30 * 24 * 60 * 60   // Every 30 days by default
    
    @objc open dynamic var momentInDayRepeatTimeInterval: TimeInterval = 20 * 60   // Every 20 minutes by default
    
    
    override open func dictionaryRepresentationKeys() -> [String] {
        let keys = super.dictionaryRepresentationKeys().filter({ $0 != #keyPath(identifier)})
        return keys.appending(contentsOf: [ #keyPath(taskIdentifier),
                                            #keyPath(schemaIdentifier),
                                            #keyPath(alwaysIncludeActivitySteps),
                                            #keyPath(trackingSurveyRepeatTimeInterval),
                                            #keyPath(momentInDayRepeatTimeInterval),
                                            #keyPath(itemsClassType),
                                            #keyPath(items),
                                            #keyPath(steps)])
    }
    
    override open func defaultValue(forKey key: String) -> Any? {
        return super.defaultValue(forKey: key)
    }
    
    override open func defaultIdentifierIfNil() -> String {
        return self.schemaIdentifier;
    }
    
    override open func setValue(_ value: Any?, forKey key: String) {
        if (key == #keyPath(items)), let arr = value as? [Any] {
            self.items = arr.mapAndFilter({ (obj) -> SBATrackedDataObject? in
                if let item = obj as? SBATrackedDataObject {
                    return item
                }
                return self.mapValue(obj, forKey: key, withClassType: self.itemsClassType) as? SBATrackedDataObject
            })
        }
        else {
            super.setValue(value, forKey: key)
        }
    }

    
    // MARK: SBABridgeTask
    
    public var taskSteps: [SBAStepTransformer] {
        return [self]
    }

    open var insertSteps: [SBAStepTransformer]?
    
    
    // MARK: SBAStepTransformer
    
    func transformToTaskAndIncludes(_ factory: SBABaseSurveyFactory, isLastStep: Bool) -> (task: SBANavigableOrderedTask?, include: SBATrackingStepIncludes?)  {
        
        let include = buildIncludes(isLastStep: isLastStep)
        
        // Setup the steps
        let (steps, trackedResults) = filteredSteps(include, factory: factory)
        let task = SBANavigableOrderedTask(identifier: self.schemaIdentifier, steps: steps)
        task.conditionalRule = self
        
        // Check the dataStore to determine if the momentInDay step map has been setup and do so if needed
        if (self.dataStore.momentInDaySteps == nil)  {
            let (activitySteps, _) = filteredSteps(.ActivityOnly, factory: factory)
            self.dataStore.momentInDaySteps = activitySteps
        }
        
        // Add the tracked results
        if trackedResults.count > 0 {
            task.appendInitialResults(contentsOf: trackedResults)
        }
        
        return (task, include)
    }
    
    open func buildIncludes(isLastStep: Bool) -> SBATrackingStepIncludes {
        
        var include: SBATrackingStepIncludes = .None
        if (isLastStep) {
            // If this is the last step then it is not being inserted into another task activity
            include = .StandAloneSurvey
        }
        else if (self.dataStore.selectedItems == nil) {
            include = .SurveyAndActivity
        }
        else if shouldIncludeChangedStep() {
            if !self.hasTrackedItems() {
                include = .ChangedOnly
            }
            else {
                include = .ChangedAndActivity
            }
        }
        else if shouldIncludeMomentInDayQuestions() {
            include = .ActivityOnly
        }
        return include
    }
    
    open func transformToStep(with factory: SBABaseSurveyFactory, isLastStep: Bool) -> ORKStep? {
        let (retTask, retInclude) = transformToTaskAndIncludes(factory, isLastStep: isLastStep)
        guard let task = retTask, let include = retInclude else { return nil }
        
        let subtaskStep = SBASubtaskStep(subtask: task)
        if (include.includeSurvey()) {
            // Only set the task and schema identifier if the full survey is included
            subtaskStep.taskIdentifier = self.taskIdentifier
            subtaskStep.schemaIdentifier = self.schemaIdentifier
        }
        
        return subtaskStep
    }
    
    // MARK: SBAConditionalRule
    
    open func shouldSkip(step: ORKStep?, with result: ORKTaskResult) -> Bool {

        // Check if this step is a tracked step. If the tracked step is nil then should *not* skip the step
        guard let trackedStep = step as? SBATrackedNavigationStep else { return false }
        
        // Otherwise, update the step with the selected items and then determine if it should be skipped
        trackedStep.update(selectedItems: self.dataStore.selectedItems ?? [])

        return trackedStep.shouldSkipStep
    }
    
    open func nextStep(previousStep: ORKStep?, nextStep: ORKStep?, with result: ORKTaskResult) -> ORKStep? {
        
        if let selectionStep = previousStep as? SBATrackedSelectionStep,
            let stepResult = result.stepResult(forStepIdentifier: selectionStep.identifier),
            let trackedResultIdentifier = selectionStep.trackedResultIdentifier,
            let _ = stepResult.result(forIdentifier: trackedResultIdentifier) as? SBATrackedDataSelectionResult {
            
            // If the selection step has a tracked data selection step added to it then update the data store
            self.dataStore.updateTrackedData(for: stepResult)
        }
        else if let previous = previousStep as? SBATrackedStep, previous.trackingType == .activity,
            let stepResult = result.stepResult(forStepIdentifier: previousStep!.identifier) {
            
            // If this is a moment in day step then update the data store
            self.dataStore.updateMomentInDay(for: stepResult)
        }
        
        return nextStep
    }
    
    public func updateSelection(selectionStep: SBATrackedSelectionStep, activityTimingStep:SBATrackedNavigationStep, taskResult:ORKTaskResult) {
        guard let stepResult = taskResult.stepResult(forStepIdentifier: selectionStep.identifier) else {
            return
        }

        // If the selection step has a tracked data selection step added to it then update the data store
        self.dataStore.updateTrackedData(for: stepResult)
        
        // Update the activity timing step with the new selected items
        activityTimingStep.update(selectedItems: self.dataStore.selectedItems ?? [])
    }
    
    // MARK: Functions for transforming and recording results
    
    open func filteredSteps(_ include: SBATrackingStepIncludes) -> [ORKStep] {
        let (steps, _) = filteredSteps(include, factory: SBAInfoManager.shared.defaultSurveyFactory)
        return steps
    }
    
    fileprivate func filteredSteps(_ include: SBATrackingStepIncludes, factory: SBABaseSurveyFactory) -> (steps: [ORKStep],trackedResults: [ORKStepResult]) {
        
        var firstActivityStepIdentifier: String?
        var trackedResults:[ORKStepResult] = []
        
        // Filter and map
        let steps: [ORKStep] = self.steps.mapAndFilter { (element) -> ORKStep? in
            
            // If the item is not of the expected protocol then ignore it
            guard let item = element as? SBASurveyItem else { return nil }
            
            // Look to see if the item has a tracking type and create the appropriate step if it does
            if let trackingItem = item as? SBATrackedStepSurveyItem,
                let trackingType = trackingItem.trackingType {
                
                // If the step should be included (or the tracking should include activity
                guard include.shouldInclude(trackingType),
                    let step = factory.createSurveyStep(item, trackingType: trackingType, trackedItems: self.items)
                else { return nil }
                
                // keep a pointer to the first activity step identifier
                if trackingType == .activity && firstActivityStepIdentifier == nil {
                    firstActivityStepIdentifier = step.identifier
                }

                // For selection step, add to tracked results
                if trackingType == .selection, let result = dataStore.stepResult(for: step) {
                    trackedResults.append(result)
                }
                
                // return the step created by the factory
                return step
            }
            else if (include.includeSurvey()) {
                // If this is the survey then all non-tracking type items are included
                // otherwise, if only including activities then they are not.
                return factory.createSurveyStep(item)
            }
            return nil
        }
        
        // Map the next step identifier back into the changed step
        if let changedStep = steps.first as? SBANavigationFormStep,
            let nextStepIdentifier = firstActivityStepIdentifier,
            let rule = changedStep.rules?.first as? SBASurveyRuleObject,
            include.nextStepIfNoChange == .activity {
            rule.skipIdentifier = nextStepIdentifier
        }
        
        return (steps, trackedResults)
    }
    
    open func findStep(_ trackingType: SBATrackingStepType) -> SBATrackedStepSurveyItem? {
        return self.steps.find({ (obj) -> Bool in
            guard let trackingItem = obj as? SBATrackedStepSurveyItem,
                let type = trackingItem.trackingType else { return false }
            return type == trackingType
        }) as? SBATrackedStepSurveyItem
    }
    
    open func shouldIncludeChangedStep() -> Bool {
        if let _ = self.findStep(.changed), let lastDate = self.dataStore.lastTrackingSurveyDate {
            let interval = self.trackingSurveyRepeatTimeInterval as TimeInterval
            return interval > 0 && lastDate.timeIntervalSinceNow < -1 * interval
        }
        else {
            return false
        }
    }
    
    open func shouldIncludeMomentInDayQuestions() -> Bool {
        guard hasTrackedItems() else { return false }
        if !alwaysIncludeActivitySteps,
            let _ = self.dataStore.momentInDayResults,
            let lastDate = self.dataStore.lastCompletionDate {
            let interval = self.momentInDayRepeatTimeInterval as TimeInterval
            return interval > 0 && lastDate.timeIntervalSinceNow < -1 * interval
        }
        else {
            return true
        }
    }
    
    open func hasTrackedItems() -> Bool {
        guard let selectedItems = self.dataStore.selectedItems else {
            return false
        }
        return selectedItems.find({ $0.tracking }) != nil
    }
}
