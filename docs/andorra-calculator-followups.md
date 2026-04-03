# Andorra Calculator Follow-Ups

## Purpose

Track deferred Andorra work that was intentionally left out of the first public rollout so it can be prepared and implemented later without re-discovery.

## Deferred Risks

### 1. Spouse-income phase-in below the full household threshold

Current behavior:
- The calculator models the simple no-income spouse or partner case only.
- It does not model the partial phase-in behavior for households below the full threshold.

Why this matters:
- This can change the taxpayer reduction and final IRPF materially for some households.

Preparation needed:
- Confirm the exact official phase-in formula and thresholds by tax year.
- Add explicit seeded parameters for the reduction curve.
- Add request and system coverage for partial spouse-income scenarios.

### 2. Reduced and startup self-employed CASS regimes

Current behavior:
- The self-employed calculator uses the seeded standard own-account CASS base for the selected year.
- It does not model startup, under-35, or other reduced-base regimes.

Why this matters:
- These regimes can materially reduce own-account social contributions and change total effective tax.

Preparation needed:
- Collect the official eligibility rules and contribution schedules for each reduced regime.
- Decide whether they should be modeled as:
  - extra inputs on one self-employed regime, or
  - separate public/hidden regimes
- Add seeded year-specific parameters for reduced bases and transition periods.

### 3. Housing-rent and other less common IRPF reductions

Current behavior:
- The Andorra rollout includes the core deductions and credits already exposed in the first version.
- Less common or edge-case IRPF reductions are not modeled yet.

Why this matters:
- Some taxpayers will still see understated relief compared with a full filing scenario.

Preparation needed:
- Build a source-backed list of deferred Andorra reductions and credits.
- Prioritize them by frequency, materiality, and UI complexity.
- Add only the ones that can be explained clearly in the shared calculator UX.

## Recommended Next Pass

1. Finalize official-source notes for spouse-income reduction mechanics.
2. Design the self-employed reduced-regime model before adding more inputs.
3. Expand the deferred deduction catalog and split it into:
   - public next-release candidates
   - research-only items
   - intentionally out-of-scope items

## Release Note

As of April 4, 2026, these risks are documented but not implemented in the live Andorra calculator.
