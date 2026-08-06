# Module 002
# Swing Detector Algorithm
Version: 1.0
Status: Design

---

# Purpose

This document defines the algorithm used by the Swing Detector.

No implementation details are included.

This document exists to ensure the implementation follows the approved strategy.

---

# Inputs

Price Series

Open

High

Low

Close

Time

Bar Index

---

# Outputs

Confirmed Swing High

Confirmed Swing Low

Internal Swing

External Swing

---

# Processing Pipeline

1.

Receive new completed candle.

↓

2.

Evaluate candidate swing.

↓

3.

Apply confirmation rules.

↓

4.

Reject invalid candidates.

↓

5.

Classify swing.

↓

6.

Store confirmed swing.

↓

7.

Publish swing.

---

# Internal State

Previous Swing

Current Candidate

Confirmed Swings

Latest High

Latest Low

---

# Rules

The implementation shall follow only the swing confirmation rules defined in the strategy documentation.

No assumptions may be introduced.

No alternative swing models may be used.

---

# Performance

Incremental processing only.

Never scan unnecessary history.

Constant memory growth limits.

---

# Failure Conditions

Duplicate swing.

Invalid chronology.

Repainting.

Broken ordering.

Invalid structure.

---

# Validation

Module passes when:

Confirmed swings match the strategy.

No repainting occurs.

Output remains deterministic.

Chronological ordering is maintained.
