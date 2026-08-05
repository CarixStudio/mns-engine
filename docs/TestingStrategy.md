# Testing Strategy

Guidelines for verifying MNS Engine code correctness, performance, and robustness.

## Types of Testing

### 1. Unit Tests
- Placed in `tests/`.
- Validate logic in `src/Include/MNS/` classes.

### 2. Backtests
- Visual and fast backtesting profiles in MT5 Strategy Tester.
- Multi-currency/multi-symbol verification.

### 3. Integration & Acceptance Tests
- End-to-end flow checks in a demo environment.
