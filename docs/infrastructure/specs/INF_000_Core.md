# Module Specification — INF-000: Core Module
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Purpose

The Core Module (`MNSCore.mqh`) provides version metadata, feature flag controls, shared result/error codes, global constants, and developer assertion checks. 

This file is the root reference header of the engine and has **zero dependencies**.

---

## 2. Responsibilities

- **Error Codes**: Enforce uniform error/success types (`HRESULT` structure) to allow structured return parsing.
- **Global Constants**: Standardize values like `MNS_INVALID_PRICE` (`DBL_MAX`), `MNS_INVALID_TIME` (`0`), and index flags.
- **Assertions**: Define a compile-time assertion macro (`MNS_Assert`) that halts execution or logs diagnostics during development.

---

## 3. Public API

This is a header-only utility file of macro definitions and constants.

```cpp
// --- Shared Error / Success Codes ---
typedef int MNS_RESULT;

#define MNS_S_OK             0x00000000    // Success
#define MNS_E_FAIL           0x80004005    // Generic Failure
#define MNS_E_INVALIDARG     0x80070057    // Invalid argument passed
#define MNS_E_OUTOFMEMORY    0x8007000E    // Array resize or allocation failed
#define MNS_E_NOTIMPL        0x80004001    // Method not yet implemented

// --- Global Constants ---
#define MNS_INVALID_PRICE    1.7976931348623157e+308 // DBL_MAX
#define MNS_INVALID_INDEX    -1
#define MNS_INVALID_TIME     0

// --- Assertion Macro ---
#ifdef MNS_ASSERT_ENABLE
    #define MNS_Assert(expression, message) \
        if (!(expression)) { \
            Alert("MNS ASSERTION FAILED: " + message); \
            ExpertRemove(); \
        }
#else
    #define MNS_Assert(expression, message)
#endif
```

---

## 4. Internal Architecture & Dependencies

- **File**: `Include/MNS/MNSCore.mqh`
- **Dependencies**: None.
- **Future Dependencies**: None.

---

## 5. Configuration & Flags

- `#define MNS_ASSERT_ENABLE`: If defined, triggers chart alerts and halts EAs when assertions fail. If undefined, the assertion code is stripped during compilation.

---

## 6. Testing Strategy

- **Test Cases**:
  1. Confirm that `MNS_INVALID_PRICE` equates to `DBL_MAX`.
  2. Confirm that when `MNS_ASSERT_ENABLE` is undefined, `MNS_Assert` does not execute (verified by passing a false condition that should otherwise halt execution).
- **Acceptance Criteria**:
  - The module compiles cleanly (0 errors, 0 warnings) as a standalone header.
  - Zero dynamic allocations occur.
