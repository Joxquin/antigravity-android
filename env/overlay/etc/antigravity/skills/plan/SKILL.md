---
name: plan
description: "Planning mode: think, investigate, and plan carefully before executing any code changes. Creates a detailed technical design implementation plan artifact (implementation_plan.md) and requests user approval before modifying code."
metadata:
  icon: assignment
---

# /plan - Implementation Planning Mode

When `/plan` is invoked, you MUST strictly operate in **planning mode**. Do NOT make any code modifications or run modifying/destructive commands until the user has reviewed and explicitly approved your plan.

---

## Operating Protocol

1. **Research & Codebase Exploration:**
   - Thoroughly explore the relevant directories, configs, and architecture.
   - Trace callers, dependencies, and potential side-effects.
   - Do NOT edit any source code or execute destructive operations during this phase.

2. **Draft the Implementation Plan Artifact:**
   - Create the plan file in the artifact directory: `<Artifact Directory>/implementation_plan.md` or `<Artifact Directory>/<plan_name>.md`.
   - Set `UserFacing: true` and `RequestFeedback: true` in the `ArtifactMetadata`.
   - The document MUST follow this structure:
     - **[Goal Description]**: Concise statement of problem and expected outcome.
     - **User Review Required**: Breaking changes, critical architecture choices, or permission changes. Use GitHub alerts (`> [!IMPORTANT]`, `> [!WARNING]`).
     - **Open Questions**: Clarifications for the user that impact design decisions.
     - **Proposed Changes**: Exact files to create (`[NEW]`), modify (`[MODIFY]`), or remove (`[DELETE]`), with code snippets or diffs grouped by layer/component.
     - **Verification Plan**: Exact test commands and manual verification steps.

3. **Wait for Approval:**
   - After creating or updating the plan artifact, inform the user with a concise summary and point them to the artifact.
   - Ask for confirmation before touching any code files.
   - Once (and ONLY once) the user explicitly confirms or approves the plan, proceed to the implementation and verification phases.
