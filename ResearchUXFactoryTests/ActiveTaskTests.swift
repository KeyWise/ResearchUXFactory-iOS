//
//  SBAActiveTaskTests.swift
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

import XCTest
import ResearchKit
import ResearchUXFactory

class SBAActiveTaskTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: Test active task factory for predefined tasks
    // syoung 03/08/2017 When adding a test for task added to the SBAActiveTaskType list, please order alphabetically.


    func testGoNoGoTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Go-No-Go",
            "schemaIdentifier"          : "Go-No-Go",
            "taskType"                  : "goNoGo",
            "intendedUseDescription"    : "intended Use Description Text",
            "localizedSteps"               : [[
                "identifier" : "conclusion",
                "title"      : "Title 123",
                "text"       : "Text 123",
                "detailText" : "Detail Text 123"
                ]
            ]
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Go-No-Go")
        
        guard let task = result as? ORKOrderedTask else {
            XCTAssert(false, "\(String(describing: result)) not of expect class")
            return
        }
        
        let expectedCount = 5
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(String(describing: task.steps.first)) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "instruction")
        XCTAssertEqual(instructionStep.text, "intended Use Description Text")
        
        // Step - Permissions
        guard let permissions = task.steps[1] as? SBAPermissionsStep else {
            XCTAssert(false, "\(task.steps[1]) not of expect class")
            return
        }
        XCTAssertEqual(permissions.permissionTypes.count, 1)
        XCTAssertEqual(permissions.permissionTypes.first?.identifier, "coremotion")
        
        // Step - Instruction
        guard let _ = task.steps[2] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }

        // Step - Active
        guard let _ = task.steps[3] as? ORKActiveStep else {
            XCTAssert(false, "\(task.steps[3]) not of expect class")
            return
        }
        
        // Step - Completion
        guard let completionStep = task.steps.last as? ORKCompletionStep else {
            XCTAssert(false, "\(String(describing: task.steps.last)) not of expect class")
            return
        }
        XCTAssertEqual(completionStep.identifier, "conclusion")
        XCTAssertEqual(completionStep.title, "Title 123")
        XCTAssertEqual(completionStep.text, "Text 123")
        XCTAssertEqual(completionStep.detailText, "Detail Text 123")
    }
    
    func testTappingTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Tapping-ABCD-1234",
            "schemaIdentifier"          : "Tapping Activity",
            "taskType"                  : "tapping",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "duration"      : 12.0,
                "handOptions"   : "right"
            ],
            "localizedSteps"               : [[
                "identifier" : "conclusion",
                "title"      : "Title 123",
                "text"       : "Text 123",
                "detailText" : "Detail Text 123"
                ]
            ]
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Tapping Activity")
        
        // syoung 07/31/2019 No longer supporting this task.
    }
    
    func testTrailmakingTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Trail-Making",
            "schemaIdentifier"          : "Trail Making",
            "taskType"                  : "trailmaking",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "trailType"                 : "A",
                "trailmakingInstruction"    : "trail making instruction"
            ],
            "localizedSteps"               : [[
                "identifier" : "conclusion",
                "title"      : "Title 123",
                "text"       : "Text 123",
                "detailText" : "Detail Text 123"
                ]
            ]
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Trail Making")
        
        guard let task = result as? ORKOrderedTask else {
            XCTAssert(false, "\(String(describing: result)) not of expect class")
            return
        }
        
        let expectedCount = 6
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(String(describing: task.steps.first)) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "instruction")
        XCTAssertEqual(instructionStep.text, "intended Use Description Text")
        
        // Step 2 - Instruction
        guard let instruction1Step = task.steps[1] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[1]) not of expect class")
            return
        }
        XCTAssertEqual(instruction1Step.identifier, "instruction1")
        
        // Step 3 - Instruction
        guard let instruction2Step = task.steps[2] as? ORKInstructionStep else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }
        XCTAssertEqual(instruction2Step.identifier, "instruction2")
        XCTAssertEqual(instruction2Step.text, "trail making instruction")
        
        
        // Countdown
        guard let countdownStep = task.steps[3] as? ORKCountdownStep else {
            XCTAssert(false, "\(task.steps[3]) not of expect class")
            return
        }
        XCTAssertEqual(countdownStep.identifier, "countdown")
        
        // Countdown
        guard let trailmakingStep = task.steps[4] as? ORKTrailmakingStep else {
            XCTAssert(false, "\(task.steps[4]) not of expect class")
            return
        }
        XCTAssertEqual(trailmakingStep.identifier, "trailmaking")
        XCTAssertEqual(trailmakingStep.trailType, ORKTrailMakingTypeIdentifier.A)
        
        // Completion
        guard let completionStep = task.steps.last as? ORKCompletionStep else {
            XCTAssert(false, "\(String(describing: task.steps.last)) not of expect class")
            return
        }
        XCTAssertEqual(completionStep.identifier, "conclusion")
        XCTAssertEqual(completionStep.title, "Title 123")
        XCTAssertEqual(completionStep.text, "Text 123")
        XCTAssertEqual(completionStep.detailText, "Detail Text 123")
    }
    
    
    func testTremorTask_Right_IncludeAll() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Tremor-ABCD-1234",
            "schemaIdentifier"          : "Tremor Activity",
            "taskType"                  : "tremor",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "duration"      : 10.0,
                "handOptions"   : "right",
            ],
            ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Tremor Activity")
        
        // syoung 07/31/2019 No longer supporting this task.
    }
    
    func testTremorTask_Both_ExcludeNoseAndElbowBent() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Tremor-ABCD-1234",
            "schemaIdentifier"          : "Tremor Activity",
            "taskType"                  : "tremor",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "duration"          : 10.0,
                "handOptions"       : "both",
                "excludePostions"   : ["elbowBent", "touchNose"]
            ],
            ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Tremor Activity")
        
        // syoung 07/31/2019 No longer supporting this task.
    }

    
    func testVoiceTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Voice-ABCD-1234",
            "schemaIdentifier"          : "Voice Activity",
            "taskType"                  : "voice",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "duration"              : 10.0,
                "speechInstruction"     : "Speech Instruction",
                "shortSpeechInstruction": "Short Speech Instruction"
            ],
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Voice Activity")

        // syoung 07/31/2019 No longer supporting this task.
    }
    
    func testWalkingTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Walking-ABCD-1234",
            "schemaIdentifier"          : "Walking Activity",
            "taskType"                  : "walking",
            "intendedUseDescription"    : "intended Use Description Text",
            "taskOptions"               : [
                "walkDuration"          : 45.0,
                "restDuration"          : 20.0,
            ],
            ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Walking Activity")
        
        // syoung 07/31/2019 No longer supporting this task.
    }
    
    // MARK: Additional functionality tests
    
    func testGroupedActiveTask() {
        
        let tappingTask: NSDictionary = [
            "taskIdentifier"            : "1-Tapping-ABCD-1234",
            "schemaIdentifier"          : "Tapping Activity",
            "surveyItemType"            : "activeTask",
            "taskType"                  : "tapping",
        ]
        
        let voiceTask: NSDictionary = [
            "taskIdentifier"            : "1-Voice-ABCD-1234",
            "schemaIdentifier"          : "Voice Activity",
            "taskType"                  : "voice",
            "intendedUseDescription"    : "intended Use Description Text",
            "predefinedExclusions"      : 0,
            ]
        
        let walkingTask: NSDictionary = [
            "taskIdentifier"            : "1-Walking-ABCD-1234",
            "schemaIdentifier"          : "Walking Activity",
            "surveyItemType"            : "activeTask",
            "taskType"                  : "walking",
            ]
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Combo-ABCD-1234",
            "steps"                 :[
                [
                    "identifier" : "introduction",
                    "text" : "This is a combo task",
                    "detailText": "Tap the button below to begin",
                    "type"  : "instruction",
                ],
                tappingTask,
                voiceTask,
                walkingTask
            ],
            "insertSteps"               :[
                [
                    "resourceName"      : "MedicationTracking",
                    "resourceBundle"    : Bundle(for: self.classForCoder).bundleIdentifier,
                    "classType"         : "TrackedDataObjectCollection"
                    ]
                ]
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "1-Combo-ABCD-1234")
        
        guard let task = result as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(String(describing: result)) not of expect class")
            return
        }
        
        let expectedCount = 7
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(String(describing: task.steps.first)) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "introduction")
        XCTAssertEqual(instructionStep.text, "This is a combo task")
        XCTAssertEqual(instructionStep.detailText, "Tap the button below to begin")
        
        // Step 2 - Medication tracking
        let medStep = task.steps[1]
        XCTAssertEqual(medStep.identifier, "Medication Tracker")
        
        // Step 3 - Tapping Subtask
        guard let tappingStep = task.steps[2] as? SBASubtaskStep,
            let tapTask = tappingStep.subtask as? ORKOrderedTask,
            let lastTapStep = tapTask.steps.last else {
            XCTAssert(false, "\(task.steps[2]) not of expect class")
            return
        }
        XCTAssertEqual(tappingStep.identifier, "Tapping Activity")
        XCTAssertNotEqual(lastTapStep.identifier, "conclusion")
        
        // Progress Step
        guard let progressStep1 = task.steps[3] as? SBAProgressStep else {
            XCTAssert(false, "\(task.steps[3]) not of expect class")
            return
        }
        let actualTitles1 = progressStep1.items!.map({ $0.description })
        let expectedTitles1 = ["\u{2705} Tapping Speed", "\u{2003}\u{2002} Voice", "\u{2003}\u{2002} Gait and Balance"]
        XCTAssertEqual(actualTitles1, expectedTitles1)
        
        
        // Step 4 - Voice Subtask
        guard let voiceStep = task.steps[4] as? SBASubtaskStep,
            let vTask = voiceStep.subtask as? ORKOrderedTask,
            let lastVoiceStep = vTask.steps.last else {
            XCTAssert(false, "\(task.steps[4]) not of expect class")
            return
        }
        XCTAssertEqual(voiceStep.identifier, "Voice Activity")
        XCTAssertEqual(lastVoiceStep.identifier, "conclusion")
        
        // Progress Step
        guard let progressStep2 = task.steps[5] as? SBAProgressStep else {
            XCTAssert(false, "\(task.steps[5]) not of expect class")
            return
        }
        let actualTitles2 = progressStep2.items!.map({ $0.description })
        let expectedTitles2 = ["\u{2705} Tapping Speed", "\u{2705} Voice", "\u{2003}\u{2002} Gait and Balance"]
        XCTAssertEqual(actualTitles2, expectedTitles2)
        
        // Step 5 - Walking Subtask
        guard let memoryStep = task.steps[6] as? SBASubtaskStep,
            let mTask = memoryStep.subtask as? ORKOrderedTask,
            let lastMemoryStep = mTask.steps.last else {
            XCTAssert(false, "\(task.steps[6]) not of expect class")
            return
        }
        XCTAssertEqual(memoryStep.identifier, "Walking Activity")
        XCTAssertEqual(lastMemoryStep.identifier, "conclusion")
        
    }
    
    func testSurveyTask() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"    : "1-StudyTracker-1234",
            "schemaIdentifier"  : "Study Drug Tracker",
            "steps"         : [
                [
                    "identifier"   : "studyDrugTiming",
                    "type"         : "singleChoiceText",
                    "title"        : "Study Drug Timing",
                    "text"         : "Indicate when the patient takes the Study Drug",
                    "items"        : [
                        [
                            "prompt" : "The patient has taken the drug now",
                            "value"   : true
                        ],
                        [
                            "prompt" : "Cancel",
                            "value"   : false
                        ]
                    ],
                ]
            ]
        ]
    
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Study Drug Tracker")
        
        guard let task = result as? ORKOrderedTask else {
            XCTAssert(false, "\(String(describing: result)) not of expect class")
            return
        }
        
        let expectedCount = 1
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }
        
        // Step 1 - Overview
        guard let formStep = task.steps.first as? ORKFormStep,
            let formItem = formStep.formItems?.first,
            let answerFormat = formItem.answerFormat as? ORKTextChoiceAnswerFormat
        else {
            XCTAssert(false, "\(String(describing: task.steps.first)) not of expect class")
            return
        }
        XCTAssertEqual(formStep.identifier, "studyDrugTiming")
        XCTAssertEqual(answerFormat.textChoices.count, 2)
    }
    
    func testTaskWithInsertSteps_Single() {
        
        let inputTask: NSDictionary = [
            "taskIdentifier"            : "1-Tapping-ABCD-1234",
            "schemaIdentifier"          : "Tapping Activity",
            "surveyItemType"            : "activeTask",
            "taskType"                  : "tapping",
            "insertSteps"               :[
                [
                    "resourceName"      : "MedicationTracking",
                    "resourceBundle"    : Bundle(for: self.classForCoder).bundleIdentifier ?? "",
                    "classType"         : "TrackedDataObjectCollection"
                ]
            ]
        ]
        
        let result = inputTask.createORKTask()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.identifier, "Tapping Activity")
        
        guard let task = result as? SBANavigableOrderedTask else {
            XCTAssert(false, "\(String(describing: result)) not of expect class")
            return
        }
        
        let expectedCount = 3
        XCTAssertEqual(task.steps.count, expectedCount, "\(task.steps)")
        guard task.steps.count == expectedCount else { return }

        // Step 1 - Overview
        guard let instructionStep = task.steps.first as? ORKInstructionStep else {
            XCTAssert(false, "\(String(describing: task.steps.first)) not of expect class")
            return
        }
        XCTAssertEqual(instructionStep.identifier, "instruction")

        // Step 2 - Medication tracking
        let medStep = task.steps[1]
        XCTAssertEqual(medStep.identifier, "Medication Tracker")

        // Step 3 - Tapping Subtask
        guard let tappingStep = task.steps[2] as? SBASubtaskStep,
            let tapTask = tappingStep.subtask as? ORKOrderedTask else {
                XCTAssert(false, "\(task.steps[2]) not of expect class")
                return
        }
        
        XCTAssertEqual(tappingStep.identifier, "Tapping Activity")
        XCTAssertEqual(tapTask.identifier, "Tapping Activity")
        
    }

}
