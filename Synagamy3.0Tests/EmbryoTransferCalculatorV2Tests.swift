//
//  EmbryoTransferCalculatorV2Tests.swift
//  Synagamy3.0Tests
//
//  Tests for the evidence-based embryo transfer prediction calculator V2
//  Validates against published literature benchmarks
//

import XCTest
@testable import Synagamy3_0

final class EmbryoTransferCalculatorV2Tests: XCTestCase {
    
    func testEuploidYoungExcellent5AA() {
        // Test optimal case: young age, excellent euploid embryo (5AA)
        let input = EmbryoTransferInput(
            oocyteAge: 32,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should achieve high success rates matching published literature
        XCTAssertGreaterThan(prediction.liveBirthRate, 0.60, "5AA euploid should exceed 60% LBR")
        XCTAssertLessThan(prediction.liveBirthRate, 0.75, "Should not exceed realistic upper bounds")
        
        // Low miscarriage rate for euploid
        XCTAssertLessThan(prediction.miscarriageRate, 0.12, "Euploid miscarriage should be <12%")
        
        // High confidence for euploid
        XCTAssertEqual(prediction.confidence, .high, "Euploid should have high confidence")
    }
    
    func testEuploidAdvancedAge() {
        // Test euploid embryo at advanced maternal age
        let input = EmbryoTransferInput(
            oocyteAge: 42,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .A, teGrade: .A),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should still have good rates per recent studies showing age-independence
        XCTAssertGreaterThan(prediction.liveBirthRate, 0.45, "Euploid at age 42 should exceed 45%")
        XCTAssertLessThan(prediction.liveBirthRate, 0.60, "But lower than young age")
    }
    
    func testBlastocystGradeImpact() {
        // Test trophectoderm grade impact (2024 research priority)
        let inputTeA = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .A),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let inputTeC = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .C),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let predictionTeA = EmbryoTransferCalculatorV2.calculatePrediction(input: inputTeA)
        let predictionTeC = EmbryoTransferCalculatorV2.calculatePrediction(input: inputTeC)
        
        // TE-A should significantly outperform TE-C
        XCTAssertGreaterThan(
            predictionTeA.liveBirthRate - predictionTeC.liveBirthRate, 
            0.15, 
            "TE-A vs TE-C should show >15% difference"
        )
    }
    
    func testMosaicLowLevelVsHighLevel() {
        // Test mosaic type impact based on 1000+ transfer data
        let inputLowLevel = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .mosaic,
            mosaicType: .lowLevel
        )
        
        let inputHighLevel = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .mosaic,
            mosaicType: .highLevel
        )
        
        let predictionLowLevel = EmbryoTransferCalculatorV2.calculatePrediction(input: inputLowLevel)
        let predictionHighLevel = EmbryoTransferCalculatorV2.calculatePrediction(input: inputHighLevel)
        
        // Low level should significantly outperform high level
        XCTAssertGreaterThan(
            predictionLowLevel.liveBirthRate, 
            predictionHighLevel.liveBirthRate * 1.5, 
            "Low level should be >1.5x high level rate"
        )
        
        // Should match published benchmarks
        XCTAssertGreaterThan(predictionLowLevel.liveBirthRate, 0.35, "Low level should exceed 35%")
        XCTAssertLessThan(predictionHighLevel.liveBirthRate, 0.25, "High level should be <25%")
    }
    
    func testUntestedAgeDecline() {
        // Test age-related decline for untested embryos (aneuploidy impact)
        let youngInput = EmbryoTransferInput(
            oocyteAge: 28,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .A, teGrade: .A),
            geneticStatus: .untested,
            mosaicType: nil
        )
        
        let oldInput = EmbryoTransferInput(
            oocyteAge: 43,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .A, teGrade: .A),
            geneticStatus: .untested,
            mosaicType: nil
        )
        
        let youngPrediction = EmbryoTransferCalculatorV2.calculatePrediction(input: youngInput)
        let oldPrediction = EmbryoTransferCalculatorV2.calculatePrediction(input: oldInput)
        
        // Should show dramatic age-related decline for untested
        XCTAssertGreaterThan(
            youngPrediction.liveBirthRate / oldPrediction.liveBirthRate,
            3.0,
            "Age 28 vs 43 should show >3x difference for untested"
        )
        
        // Match SART age-stratified expectations
        XCTAssertGreaterThan(youngPrediction.liveBirthRate, 0.45, "Young untested should exceed 45%")
        XCTAssertLessThan(oldPrediction.liveBirthRate, 0.20, "Old untested should be <20%")
    }
    
    func testAneuploidLowRates() {
        // Test aneuploid embryos (rarely transferred)
        let input = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A),
            geneticStatus: .aneuploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have very low success rates regardless of morphology
        XCTAssertLessThan(prediction.liveBirthRate, 0.05, "Aneuploid should be <5% LBR")
        XCTAssertGreaterThan(prediction.miscarriageRate, 0.50, "Aneuploid should have >50% miscarriage")
        XCTAssertEqual(prediction.confidence, .low, "Aneuploid should have low confidence")
    }
    
    func testDay5VsDay6() {
        // Test day of development impact
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
        
        let predictionDay5 = EmbryoTransferCalculatorV2.calculatePrediction(input: inputDay5)
        let predictionDay6 = EmbryoTransferCalculatorV2.calculatePrediction(input: inputDay6)
        
        // Day 5 should have modest advantage
        XCTAssertGreaterThan(predictionDay5.liveBirthRate, predictionDay6.liveBirthRate)
        
        // Difference should be modest for euploid embryos
        let difference = predictionDay5.liveBirthRate - predictionDay6.liveBirthRate
        XCTAssertLessThan(difference, 0.08, "Day difference should be <8% for euploid")
    }
    
    func testExpansionGradeOrder() {
        // Test that expansion grades follow expected order: 5 > 4 > 6 > 3
        let stage3 = BlastocystGrade(expansion: .stage3, icmGrade: .A, teGrade: .A)
        let stage4 = BlastocystGrade(expansion: .stage4, icmGrade: .A, teGrade: .A)
        let stage5 = BlastocystGrade(expansion: .stage5, icmGrade: .A, teGrade: .A)
        let stage6 = BlastocystGrade(expansion: .stage6, icmGrade: .A, teGrade: .A)
        
        // Test expected order based on literature
        XCTAssertGreaterThan(stage5.liveBirthMultiplier, stage4.liveBirthMultiplier)
        XCTAssertGreaterThan(stage4.liveBirthMultiplier, stage6.liveBirthMultiplier)
        XCTAssertGreaterThan(stage6.liveBirthMultiplier, stage3.liveBirthMultiplier)
    }
    
    func testReferencesIncluded() {
        // Verify comprehensive reference list
        let input = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculator.calculatePrediction(input: input)
        
        // Should have comprehensive reference list
        XCTAssertGreaterThanOrEqual(prediction.references.count, 6, "Should have ≥6 references")
        
        // Should include key 2024 studies
        XCTAssertTrue(prediction.references.contains { $0.contains("2024") }, "Should include 2024 studies")
        XCTAssertTrue(prediction.references.contains { $0.contains("PMC11595274") }, "Should include trophectoderm study")
        XCTAssertTrue(prediction.references.contains { $0.contains("SART") }, "Should include SART data")
        
        // Should have methodology description
        XCTAssertFalse(prediction.methodology.isEmpty, "Should have methodology description")
    }
    
    func testConfidenceLevels() {
        // Test confidence assignment logic
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
        
        let aneuploidInput = EmbryoTransferInput(
            oocyteAge: 35,
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .aneuploid,
            mosaicType: nil
        )
        
        let euploidPrediction = EmbryoTransferCalculatorV2.calculatePrediction(input: euploidInput)
        let mosaicPrediction = EmbryoTransferCalculatorV2.calculatePrediction(input: mosaicInput)
        let aneuploidPrediction = EmbryoTransferCalculatorV2.calculatePrediction(input: aneuploidInput)
        
        XCTAssertEqual(euploidPrediction.confidence, .high, "Euploid should have high confidence")
        XCTAssertEqual(mosaicPrediction.confidence, .moderate, "Mosaic should have moderate confidence")
        XCTAssertEqual(aneuploidPrediction.confidence, .low, "Aneuploid should have low confidence")
    }
    
    func testInvalidInput() {
        // Test invalid age handling
        let invalidInput = EmbryoTransferInput(
            oocyteAge: 15, // Too young
            embryoDay: .day5,
            blastocystGrade: BlastocystGrade(expansion: .stage4, icmGrade: .B, teGrade: .B),
            geneticStatus: .euploid,
            mosaicType: nil
        )
        
        let prediction = EmbryoTransferCalculatorV2.calculatePrediction(input: invalidInput)
        
        XCTAssertEqual(prediction.liveBirthRate, 0, "Invalid input should return 0% rates")
        XCTAssertEqual(prediction.confidence, .low, "Invalid input should have low confidence")
    }
}