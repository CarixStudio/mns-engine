# Module Specification — INF-005: Serialization Interfaces
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Purpose

The Serialization module (`MNSSerializer.mqh`) defines standardized interfaces for converting memory objects (e.g., swing points, structure histories, break entries) into binary or text-based disk formats, and vice versa. 

This enables state preservation across terminal restarts, avoiding re-calculation overhead on startup.

---

## 2. Responsibilities

- **Serialization Contract**: Expose unified interfaces (`IMNSSerializable`) to enforce standard file writing and reading APIs.
- **Data Safety**: Standardize data layout patterns for writing files to the MT5 MQL5 local workspace.

---

## 3. Public API

```cpp
class IMNSSerializable
{
public:
    virtual ~IMNSSerializable() {}

    /// @brief Serializes the object state into a file handle.
    /// @param fileHandle Open MQL5 file handle with write permissions.
    /// @return MNS_RESULT status code.
    virtual MNS_RESULT Serialize(int fileHandle) = 0;

    /// @brief Deserializes the object state from a file handle.
    /// @param fileHandle Open MQL5 file handle with read permissions.
    /// @return MNS_RESULT status code.
    virtual MNS_RESULT Deserialize(int fileHandle) = 0;
};
```

---

## 4. Internal Architecture & Dependencies

- **File**: `Include/MNS/MNSSerializer.mqh`
- **Dependencies**: `MNSCore.mqh`
- **Data Design**: Implementing classes must serialize elements in raw binary mode to maximize performance. Struct sizes and field orders must remain fixed to prevent alignment/versioning mismatches.

---

## 5. Testing & Acceptance Criteria

- **Test Cases**:
  1. Confirm that mock structures implementing `IMNSSerializable` write their values to disk and recover them identically.
  2. Verify that deserialization of a corrupted or incomplete file returns `MNS_E_FAIL` instead of causing access violations.
- **Acceptance Criteria**:
  - Standalone header compiles cleanly.
  - No heap allocation leaks are caused by object instantiation and destruction.
