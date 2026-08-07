# Infrastructure Architecture & Standards (INF-ARCHITECTURE)
# MNS Trading Engine
Version: 1.0
Status: Approved

---

## 1. Directory Structure

All Shared Infrastructure modules will reside in the core MQL5 repository folders. No files should be written to temporary directories.

```
MQL5/
├── Include/
│   └── MNS/
│       ├── MNSCore.mqh            # INF-000 (Constants, Error Codes, Assertions)
│       ├── MNSLogger.mqh          # INF-001 (Logging System)
│       ├── MNSUtils.mqh           # INF-002 (Utility Library)
│       ├── MNSVolatility.mqh      # INF-003 (ATR Helper)
│       ├── MNSConfig.mqh          # INF-004 (Configuration)
│       ├── MNSSerializer.mqh      # INF-005 (Serialization Interfaces)
│       ├── MNSTestSuite.mqh       # INF-006 (Testing Framework)
│       └── MNSProfiler.mqh        # INF-007 (Performance Monitor)
```

---

## 2. Dependency Graph

To prevent circular references and maintain strict module separation, the dependency hierarchy must be followed.

```
       [INF-000: MNSCore] (Global engine state, result codes)
               │
      ┌────────┴────────┬─────────────────┐
      ▼                 ▼                 ▼
[INF-001: Logger]  [INF-002: Utils]  [INF-006: TestSuite]
      │                 │                 │
      ├─────────────────┼─────────────────┤
      ▼                 ▼                 ▼
[INF-003: Volatility] [INF-004: Config] [INF-005: Serializer]
      │                 │
      └────────┬────────┘
               ▼
[INF-007: PerformanceProfiler]
```

### Dependency Rules:
1. `MNSCore.mqh` is the absolute foundation. It must not include any other header.
2. Low-level utilities (`MNSUtils.mqh`, `MNSLogger.mqh`) can be consumed by higher-level tools like `MNSConfig.mqh` or `MNSVolatility.mqh`.
3. No infrastructure module may include or depend on any trading engine module (e.g., `CSwingDetector` or `CStructureEngine`).

---

## 3. MQL5 Standards & Constraints

### Memory Management
- **No Raw Pointers**: Never use standard raw pointers (`new` operator) without an associated destructor. Prefer values, arrays, or instances managed inside parent classes.
- **Pass by Reference**: Large structs and arrays must be passed as `const` references (e.g., `const double &array[]`) to avoid data copies.
- **Buffer Safety**: All arrays passed into modules must be validated for range limits to prevent index-out-of-bounds crashes.

### Compile-time Performance
- Logging and profiling macros must resolve to nothing if their toggle defines are not set.
- Example pattern for stripping logs:
```cpp
#ifdef MNS_LOG_DEBUG_ENABLE
    #define MNS_LogDebug(msg) CMNSLogger::Log(LOG_LEVEL_DEBUG, msg)
#else
    #define MNS_LogDebug(msg) 
#endif
```

---

## 4. Naming Conventions

To maintain a consistent codebase, use the following prefixes and casings:

| Code Object | Pattern | Example |
| :--- | :--- | :--- |
| **Classes** | UpperCamelCase prefixed with `C` | `CMNSLogger` |
| **Structures** | UpperCamelCase prefixed with `S` | `SMarketState` |
| **Interfaces** | UpperCamelCase prefixed with `I` | `IMNSSerializable` |
| **Functions** | UpperCamelCase | `GetLatestBOS()` |
| **Constants** | UPPER_SNAKE_CASE prefixed with `MNS_` | `MNS_INVALID_PRICE` |
| **Macros** | UPPER_SNAKE_CASE prefixed with `MNS_` | `MNS_ASSERT` |
| **Variables** | camelCase with prefix (`m_` member, `t_` static) | `m_isInitialized`, `count` |
