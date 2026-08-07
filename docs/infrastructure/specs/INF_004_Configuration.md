# Module Specification — INF-004: Configuration System
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Purpose

The Configuration System (`MNSConfig.mqh`) manages engine input variables, settings profiles, and dynamic parameters. It validates boundary ranges at runtime and maps config inputs to active memory values.

---

## 2. Responsibilities

- **Profile Loading**: Read parameter values from local profiles or file templates.
- **Validation**: Enforce minimum/maximum limits for indicators (e.g., `depth` cannot be negative or larger than `1000`).
- **Dynamic Access**: Provide getters and setters for core strategy parameters, enabling live tuning.

---

## 3. Public API

```cpp
struct SEngineConfig
{
    int    externalDepth;
    int    internalDepth;
    double atrTolerance;
    double minBreakDistance;
    double confidenceThreshold;
    bool   logEnable;
    int    logLevel;
};

class CMNSConfig
{
private:
    static SEngineConfig s_config;

public:
    /// @brief Sets default configuration values.
    static void SetDefaults();

    /// @brief Loads settings from a key-value file on disk.
    static bool LoadFromFile(string fileName);

    /// @brief Returns the active engine configuration.
    static SEngineConfig GetActive();

    /// @brief Updates a specific configuration attribute dynamically.
    static bool UpdateParameter(string name, double value);
};
```

---

## 4. Internal Architecture & Dependencies

- **File**: `Include/MNS/MNSConfig.mqh`
- **Dependencies**: `MNSCore.mqh`, `MNSUtils.mqh`
- **File Format**: Standard INI key-value format (e.g., `externalDepth=15`). File reading is restricted to MQL5 local sandbox directories.

---

## 5. Testing & Acceptance Criteria

- **Test Cases**:
  1. Confirm that `SetDefaults` sets correct initial values.
  2. Verify that `UpdateParameter` rejects values outside of logical boundaries (e.g., setting `externalDepth = -5` should return false and not modify the config).
  3. Validate that a file containing invalid key names fails gracefully without crashing the engine.
- **Acceptance Criteria**:
  - Standalone header compiles cleanly.
  - Runtime validation prevents corrupt configurations.
