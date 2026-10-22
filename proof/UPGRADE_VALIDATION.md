# Upgrade validation - 2026-10-22

Recorded run: https://github.com/SandeepGorrepati/axi4-lite-pcie-bridge/actions/runs/39756281934

Code: 5245b1dc4e821e5b2fe1e55ca45e8bf5f7d86d6f. Legacy 12 data checks and independent 1,075-pair oracle stress passed. The stress test requires exactly 2,152 packet transfers and completions across reset, including recovery transactions. Its original display called errors DECERR; the checked numeric policy was SLVERR (2), and the label is corrected in the current source.

The suite checks channel skew, all byte masks, AXI and packet stalls, invalid-address behavior, alias protection, partial-write reset cancellation, and recovery. Finite simulation does not establish complete protocol compliance.
