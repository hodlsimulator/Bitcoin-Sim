//
//  FactorCatalog.swift
//  BTCMonteCarlo
//
//  Created by . . on 04/02/2025.
//

import Foundation
import SwiftUI

struct FactorDefinition {
    let name: String
    
    /// Weekly range & default
    let minWeekly: Double
    let midWeekly: Double
    let maxWeekly: Double
    
    /// Monthly range & default
    let minMonthly: Double
    let midMonthly: Double
    let maxMonthly: Double
}

enum FactorCatalog {
    static let all: [String: FactorDefinition] = [
        
        // =======================
        // MARK: - BULLISH FACTORS
        // =======================
        
        // 1) HALVING
        "Halving": FactorDefinition(
            name: "Halving",
            // Weekly
            minWeekly: 0.2773386887,
            midWeekly: 0.3298386887,
            maxWeekly: 0.3823386887,
            // Monthly
            minMonthly: 0.2975,
            midMonthly: 0.35,
            maxMonthly: 0.4025
        ),
        
        // 2) INSTITUTIONAL DEMAND
        "InstitutionalDemand": FactorDefinition(
            name: "InstitutionalDemand",
            // Weekly
            minWeekly: 0.00105315,
            midWeekly: 0.001239,
            maxWeekly: 0.00142485,
            // Monthly
            minMonthly: 0.0048101384,
            midMonthly: 0.0056589855,
            maxMonthly: 0.0065078326
        ),
        
        // 3) COUNTRY ADOPTION
        "CountryAdoption": FactorDefinition(
            name: "CountryAdoption",
            // Weekly
            minWeekly: 0.0009882799977,
            midWeekly: 0.0011375879977,
            maxWeekly: 0.0012868959977,
            // Monthly
            minMonthly: 0.004688188952320099,
            midMonthly: 0.005515515952320099,
            maxMonthly: 0.006342842952320099
        ),
        
        // 4) REGULATORY CLARITY
        "RegulatoryClarity": FactorDefinition(
            name: "RegulatoryClarity",
            // Weekly
            minWeekly: 0.0005979474861605167,
            midWeekly: 0.0007170254861605167,
            maxWeekly: 0.0008361034861605167,
            // Monthly
            minMonthly: 0.0034626727,
            midMonthly: 0.0040737327,
            maxMonthly: 0.0046847927
        ),
        
        // 5) ETF APPROVAL
        "EtfApproval": FactorDefinition(
            name: "EtfApproval",
            // Weekly
            minWeekly: 0.0014880183160305023,
            midWeekly: 0.0017880183160305023,
            maxWeekly: 0.0020880183160305023,
            // Monthly
            minMonthly: 0.0048571421,
            midMonthly: 0.0057142851,
            maxMonthly: 0.0065714281
        ),
        
        // 6) TECH BREAKTHROUGH
        "TechBreakthrough": FactorDefinition(
            name: "TechBreakthrough",
            // Weekly
            minWeekly: 0.0005015753579173088,
            midWeekly: 0.0006083193579173088,
            maxWeekly: 0.0007150633579173088,
            // Monthly
            minMonthly: 0.0024129091,
            midMonthly: 0.0028387091,
            maxMonthly: 0.0032645091
        ),
        
        // 7) SCARCITY EVENTS
        "ScarcityEvents": FactorDefinition(
            name: "ScarcityEvents",
            // Weekly
            minWeekly: 0.00035112353681182863,
            midWeekly: 0.00041308753681182863,
            maxWeekly: 0.00047505153681182863,
            // Monthly
            minMonthly: 0.0027989405475521085,
            midMonthly: 0.0032928705475521085,
            maxMonthly: 0.0037868005475521085
        ),
        
        // 8) GLOBAL MACRO HEDGE
        "GlobalMacroHedge": FactorDefinition(
            name: "GlobalMacroHedge",
            // Weekly
            minWeekly: 0.0002868789724932909,
            midWeekly: 0.0003497809724932909,
            maxWeekly: 0.0004126829724932909,
            // Monthly
            minMonthly: 0.0027576037,
            midMonthly: 0.0032442397,
            maxMonthly: 0.0037308757
        ),
        
        // 9) STABLECOIN SHIFT
        "StablecoinShift": FactorDefinition(
            name: "StablecoinShift",
            // Weekly
            minWeekly: 0.0002704809116327763,
            midWeekly: 0.0003312209116327763,
            maxWeekly: 0.0003919609116327763,
            // Monthly
            minMonthly: 0.0019585255,
            midMonthly: 0.0023041475,
            maxMonthly: 0.0026497695
        ),
        
        // 10) DEMOGRAPHIC ADOPTION
        "DemographicAdoption": FactorDefinition(
            name: "DemographicAdoption",
            // Weekly
            minWeekly: 0.0008661432036626339,
            midWeekly: 0.0010619932036626339,
            maxWeekly: 0.0012578432036626339,
            // Monthly
            minMonthly: 0.006197455714649915,
            midMonthly: 0.007291124714649915,
            maxMonthly: 0.008384793714649915
        ),
        
        // 11) ALTCOIN FLIGHT
        "AltcoinFlight": FactorDefinition(
            name: "AltcoinFlight",
            // Weekly
            minWeekly: 0.0002381864461803342,
            midWeekly: 0.0002802194461803342,
            maxWeekly: 0.0003222524461803342,
            // Monthly
            minMonthly: 0.0018331797,
            midMonthly: 0.0021566817,
            maxMonthly: 0.0024801837
        ),
        
        // 12) ADOPTION FACTOR
        "AdoptionFactor": FactorDefinition(
            name: "AdoptionFactor",
            // Weekly
            minWeekly: 0.0013638349088897705,
            midWeekly: 0.0016045109088897705,
            maxWeekly: 0.0018451869088897705,
            // Monthly
            minMonthly: 0.012461815934071304,
            midMonthly: 0.014660959934071304,
            maxMonthly: 0.016860103934071304
        ),
        
        
        // =======================
        // MARK: - BEARISH FACTORS
        // =======================
        
        // 13) REGULATORY CLAMPDOWN
        "RegClampdown": FactorDefinition(
            name: "RegClampdown",
            // Weekly
            minWeekly: -0.0014273392243542672,
            midWeekly: -0.0011361452243542672,
            maxWeekly: -0.0008449512243542672,
            // Monthly
            minMonthly: -0.023,
            midMonthly: -0.02,
            maxMonthly: -0.017
        ),
        
        // 14) COMPETITOR COIN
        "CompetitorCoin": FactorDefinition(
            name: "CompetitorCoin",
            // Weekly
            minWeekly: -0.0011842141746411323,
            midWeekly: -0.0010148181746411323,
            maxWeekly: -0.0008454221746411323,
            // Monthly
            minMonthly: -0.0092,
            midMonthly: -0.008,
            maxMonthly: -0.0068
        ),
        
        // 15) SECURITY BREACH
        "SecurityBreach": FactorDefinition(
            name: "SecurityBreach",
            // Weekly
            minWeekly: -0.0012819675168380737,
            midWeekly: -0.0010914715168380737,
            maxWeekly: -0.0009009755168380737,
            // Monthly
            minMonthly: -0.00805,
            midMonthly: -0.007,
            maxMonthly: -0.00595
        ),
        
        // 16) BUBBLE POP
        "BubblePop": FactorDefinition(
            name: "BubblePop",
            // Weekly
            minWeekly: -0.002244817890762329,
            midWeekly: -0.001762673890762329,
            maxWeekly: -0.001280529890762329,
            // Monthly
            minMonthly: -0.0115,
            midMonthly: -0.01,
            maxMonthly: -0.0085
        ),
        
        // 17) STABLECOIN MELTDOWN
        "StablecoinMeltdown": FactorDefinition(
            name: "StablecoinMeltdown",
            // Weekly
            minWeekly: -0.0009681346159477233,
            midWeekly: -0.0007141026159477233,
            maxWeekly: -0.0004600706159477233,
            // Monthly
            minMonthly: -0.013,
            midMonthly: -0.01,
            maxMonthly: -0.007
        ),
        
        // 18) BLACK SWAN
        "BlackSwan": FactorDefinition(
            name: "BlackSwan",
            // Weekly
            minWeekly: -0.478662,
            midWeekly: -0.398885,
            maxWeekly: -0.319108,
            // Monthly
            minMonthly: -0.48,
            midMonthly: -0.4,
            maxMonthly: -0.32
        ),
        
        // 19) BEAR MARKET
        "BearMarket": FactorDefinition(
            name: "BearMarket",
            // Weekly
            minWeekly: -0.0010278802752494812,
            midWeekly: -0.0008778802752494812,
            maxWeekly: -0.0007278802752494812,
            // Monthly
            minMonthly: -0.013,
            midMonthly: -0.01,
            maxMonthly: -0.007
        ),
        
        // 20) MATURING MARKET
        "MaturingMarket": FactorDefinition(
            name: "MaturingMarket",
            // Weekly
            minWeekly: -0.0020343461055486196,
            midWeekly: -0.0015440231055486196,
            maxWeekly: -0.0010537001055486196,
            // Monthly
            minMonthly: -0.013,
            midMonthly: -0.01,
            maxMonthly: -0.007
        ),
        
        // 21) RECESSION
        "Recession": FactorDefinition(
            name: "Recession",
            // Weekly
            minWeekly: -0.0010516462467487811,
            midWeekly: -0.0009005491467487811,
            maxWeekly: -0.0007494520467487811,
            // Monthly
            minMonthly: -0.0015958890,
            midMonthly: -0.0014508080482482913,
            maxMonthly: -0.0013057270
        )
    ]
}
