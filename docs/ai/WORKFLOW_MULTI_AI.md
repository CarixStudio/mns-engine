# MNS Trading Engine
# Multi-AI Team Workflow Specification
Version: 1.0
Status: Approved

---

# Purpose

This document defines the process for developing the MNS Trading Engine using two distinct AI agents:
1. **AI Coordinator (Antigravity)**: Responsible for architecture, specs, testing, and alignment.
2. **AI Generator (External Agent)**: Responsible for code generation based on specifications.

This separation of concerns ensures that code generation is strictly validated against specifications and strategy documents by an independent agent.

---

# The Workflow Lifecycle (per Module)

Follow this sequence exactly for every module in the roadmap.

```
       AI Coordinator (Antigravity)
        [Creates Spec & Prompt]
                   │
                   ▼
           User (Copy/Paste)
      [Feeds Prompt to Generator AI]
                   │
                   ▼
          Generator AI (e.g. Claude/GPT)
         [Generates CModule.mqh]
                   │
                   ▼
           User (Copy/Paste)
       [Saves code to CModule.mqh]
                   │
                   ▼
       AI Coordinator (Antigravity)
    [Updates Test Harness & Runs Build]
                   │
                   ▼
            User (MetaEditor)
          [Presses F7 to Compile]
                   │
         ┌─────────┴─────────┐
         ▼                   ▼
      [Errors]           [0 Errors]
         │                   │
         ▼                   ▼
  AI Coordinator          User (MT5)
 [Generates fix]      [Runs Test Harness]
         │                   │
         │                   ▼
         │               User (MT5)
         │           [Copies Experts Log]
         │                   │
         │                   ▼
         │             AI Coordinator
         │           [Verifies Results]
         │                   │
         ▼                   ▼
       [Sync]         [Mark Complete]
```

---

## Detailed Step Checklist

### Step 1 — Coordinator Designs Spec & Prompt (Antigravity)
* **Antigravity** reads `kennystrstegy.md` and outputs:
  1. The Module Specification (e.g. `docs/modules/003_StructureEngine.md`).
  2. The custom **AI Generator Prompt** containing target class structure, rules, inputs, outputs, and dependencies.
* **Status**: Waiting on User copy-paste.

### Step 2 — Code Generation (External AI)
* **User** copies the Generator Prompt created by Antigravity.
* **User** pastes it into the external Generator AI (ChatGPT, Claude, etc.) along with the required context files.
* **Generator AI** outputs the complete MQL5 source code.

### Step 3 — Saving the Source Code
* **User** copies the generated MQL5 code.
* **User** saves it into the target header file (e.g. `Include/MNS/CStructureEngine.mqh`).

### Step 4 — Harness Update & Build (Antigravity)
* **User** tells Antigravity: *"Code has been saved to [filename]"*.
* **Antigravity** updates the `MNS_TestHarness.mq5` to include the new module and write assertions for it.
* **Antigravity** runs `tools/build.ps1` to sync the new module and the updated harness into the MT5 directories.

### Step 5 — Compilation (User)
* **User** opens MetaEditor.
* **User** opens `Experts/MNS_TestHarness/MNS_TestHarness.mq5`.
* **User** presses **F7** to compile.

* **Scenario A: If there are compile errors**
  1. **User** screenshots or copies the errors and sends them to Antigravity.
  2. **Antigravity** classifies the errors (using `PROMPT_DEBUG_MODULE.md`), explains the cause, and edits the module or harness code to fix it.
  3. **Antigravity** runs `build.ps1` to redeploy.
  4. Go back to Step 5.

* **Scenario B: If compile succeeds**
  1. Proceed to Step 6.

### Step 6 — Run Tests (User)
* **User** goes to MT5 and refreshes the Navigator.
* **User** opens the **Experts** tab in the bottom Toolbox panel (**Ctrl + T**).
* **User** drags `MNS_TestHarness` onto a chart.
* **User** copies the logs printed in the Experts tab.

### Step 7 — Verification & Roadmap Update (Antigravity)
* **User** pastes the log output to Antigravity.
* **Antigravity** checks that all assertions passed.
* **Antigravity** updates `docs/Roadmap.md` to mark the module as **Complete (Passed)**.
* **Antigravity** presents the plan for the next module.

---

# AI Context Packages

When prompting the external Generator AI, always supply the following package:

1. **The Generator Prompt** (created by Antigravity in Step 1).
2. **Current `MNSTypes.mqh`** (for shared structures).
3. **Previous modules** that the target module depends on.
4. **`docs/ai/ARCHITECTURE_RULES.md`** (so it doesn't break design rules).
