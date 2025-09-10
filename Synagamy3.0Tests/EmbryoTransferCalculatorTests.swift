//
//  EmbryoTransferCalculatorTests.swift
//  Synagamy3.0Tests
//
//  Tests for the embryo transfer prediction calculator
//

import XCTest
@testable import Synagamy3_0

final class EmbryoTransferCalculatorTests: XCTestCase {
    
    func testEuploidYoungAgeExcellentGrade() {
        // Test case: Young oocyte age with excellent euploid embryo (5AA)
        let input = EmbryoTransferInput(
            oocyteAge: 30,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have high success rate based on updated CCRM data (>70%)
        XCTAssertGreaterThan(prediction.liveBirthRate, 0.70)
        XCTAssertLessThanOrEqual(prediction.liveBirthRate, 0.85)
        
        // Miscarriage rate should be low for euploid
        XCTAssertLessThan(prediction.miscarriageRate, 0.10)
    }
    
    func testEuploidOlderAgeFairGrade() {
        // Test case: Older oocyte age with fair grade euploid embryo (3BC)
        let input = EmbryoTransferInput(
            oocyteAge: 42,
            embryoDay: .day6,
            blastocystGrade: BlastocystGrade(expansion: .stage3, icmGrade: .B, teGrade: .C),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have lower success rate due to age and grade
        XCTAssertGreaterThan(prediction.liveBirthRate, 0.15)
        XCTAssertLessThan(prediction.liveBirthRate, 0.30)
    }
    
    func testMosaicLowSegmental() {
        // Test case: Mosaic embryo with best prognosis type (4BB)
        let input = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .mosaic,
            mosaicType: .lowLevel
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have moderate success rate (around 40-50%)
        XCTAssertGreaterThan(prediction.liveBirthRate, 0.35)
        XCTAssertLessThan(prediction.liveBirthRate, 0.55)
        
        // Higher miscarriage rate for mosaic
        XCTAssertGreaterThan(prediction.miscarriageRate, 0.25)
    }
    
    func testMosaicHighComplex() {
        // Test case: Mosaic embryo with poorest prognosis (3BC)
        let input = EmbryoTransferInput(
            oocyteAge: 38,
            embryoDay: .day6,
            blastocystGrade: BlastocystGrade(expansion: .stage3, icmGrade: .B, teGrade: .C),
            geneticStatus: .mosaic,
            mosaicType: .highLevel
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have low success rate
        XCTAssertLessThan(prediction.liveBirthRate, 0.25)
    }
    
    func testAneuploidEmbryo() {
        // Test case: Aneuploid embryo (associated with lower success rates)
        let input = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A),
            geneticStatus: .aneuploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have very low success rate
        XCTAssertLessThanOrEqual(prediction.liveBirthRate, 0.10)
        
        // High miscarriage rate
        XCTAssertGreaterThan(prediction.miscarriageRate, 0.40)
    }
    
    func testUntestedYoungExcellent() {
        // Test case: Young oocyte age with excellent untested embryo (5AA)
        let input = EmbryoTransferInput(
            oocyteAge: 28,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A),
            geneticStatus: .untested,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have good success rate for young age with excellent untested embryo
        XCTAssertGreaterThan(prediction.liveBirthRate, 0.60)
        XCTAssertLessThan(prediction.liveBirthRate, 0.70)
    }
    
    func testUntestedOlderPoor() {
        // Test case: Older oocyte age with poor grade untested embryo (3CC)
        let input = EmbryoTransferInput(
            oocyteAge: 43,
            embryoDay: .day6,
            blastocystGrade: BlastocystGrade(expansion: .stage3, icmGrade: .C, teGrade: .C),
            geneticStatus: .untested,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have very low success rate
        XCTAssertLessThan(prediction.liveBirthRate, 0.15)
    }
    
    func testDay5VsDay6Comparison() {
        // Test that Day 5 embryos have better rates than Day 6
        let inputDay5 = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let inputDay6 = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day6,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let predictionDay5 = EmbryoTransferCalculator.calculatePrediction(input: inputDay5)
        let predictionDay6 = EmbryoTransferCalculator.calculatePrediction(input: inputDay6)
        
        // Day 5 should have higher success rate
        XCTAssertGreaterThan(predictionDay5.liveBirthRate, predictionDay6.liveBirthRate)
    }
    
    func testInvalidAge() {
        // Test case: Invalid age
        let input = EmbryoTransferInput(
            oocyteAge: 15, // Too young
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should return zero rates for invalid input
        XCTAssertEqual(prediction.liveBirthRate, 0)
        XCTAssertEqual(prediction.confidence, "Invalid input")
    }
    
    func testConfidenceLevels() {
        // Test confidence strings for different genetic statuses
        let euploidInput = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let mosaicInput = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .mosaic,
            mosaicType: .lowLevel
        )
        
        let euploidPrediction = EmbryoTransferCalculator.calculatePrediction(input: euploidInput)
        let mosaicPrediction = EmbryoTransferCalculator.calculatePrediction(input: mosaicInput)
        
        XCTAssertTrue(euploidPrediction.confidence.contains("High"))
        XCTAssertTrue(mosaicPrediction.confidence.contains("Moderate"))
    }
    
    func testBlastocystGradeImpact() {
        // Test that 5AA has better rates than 3CC for same conditions
        let input5AA = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A), // Best grade
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let input3CC = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage3, icmGrade: .C, teGrade: .C), // Poor grade
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction5AA = EmbryoTransferCalculator.calculatePrediction(input: input5AA)
        let prediction3CC = EmbryoTransferCalculator.calculatePrediction(input: input3CC)
        
        // 5AA should have significantly higher success rate than 3CC
        XCTAssertGreaterThan(prediction5AA.liveBirthRate, prediction3CC.liveBirthRate)
        
        // The difference should be substantial (at least 20% points)
        XCTAssertGreaterThan(prediction5AA.liveBirthRate - prediction3CC.liveBirthRate, 0.20)
    }
    
    func testExpansionStageImpact() {
        // Test that expansion stage 5 is better than 3 for same ICM/TE grades
        let input5AA = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let input3AA = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage3, icmGrade: .A, teGrade: .A),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction5AA = EmbryoTransferCalculator.calculatePrediction(input: input5AA)
        let prediction3AA = EmbryoTransferCalculator.calculatePrediction(input: input3AA)
        
        // 5AA should have higher success rate than 3AA
        XCTAssertGreaterThan(prediction5AA.liveBirthRate, prediction3AA.liveBirthRate)
    }
}