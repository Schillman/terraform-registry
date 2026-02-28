---
phase: quick
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - SKILL.md
  - CLAUDE.md
  - .planning/STATE.md
autonomous: true
requirements: []
must_haves:
  truths:
    - "No file in the repo instructs the agent to ask a human before acting"
    - "All operations are governed by workflow check status, not human gate"
    - "STATE.md decision log reflects the updated autonomy policy"
  artifacts:
    - path: "SKILL.md"
      provides: "Updated autonomy matrix — all rows read 'Freely — workflow checks must pass'"
      contains: "workflow checks must pass"
    - path: "CLAUDE.md"
      provides: "Updated autonomy description — no mention of human approval"
    - path: ".planning/STATE.md"
      provides: "Updated [Init] decision for agent autonomy"
  key_links:
    - from: "CLAUDE.md"
      to: "SKILL.md"
      via: "agents read CLAUDE.md first, then follow @SKILL.md reference"
      pattern: "read.*SKILL\\.md"
---

<objective>
Remove every mention of requiring human approval from agent-facing documents and replace with a workflow-check-based gate.

Purpose: The project's CI pipeline is the safety net. If all workflow checks pass, the agent may proceed with any operation without pausing for human sign-off.
Output: SKILL.md autonomy matrix, CLAUDE.md description bullet, and STATE.md decision entry all reflect the new policy.
</objective>

<execution_context>
@/Users/p950cvo/.claude/get-shit-done/workflows/execute-plan.md
@/Users/p950cvo/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Update SKILL.md autonomy matrix</name>
  <files>SKILL.md</files>
  <action>
    In Section 3 (Autonomy Matrix), replace the four "Must ask human first" rows with "Freely — workflow checks must pass".

    Current rows to change:
    - `| Delete files | Must ask human first |`
    - `| Force push | Must ask human first |`
    - `| Create releases | Must ask human first |`
    - `| Modify branch protection rules | Must ask human first |`

    Replace each with the pattern:
    `| {Operation} | Freely — workflow checks must pass |`

    The two rows already reading "Freely — no approval needed" remain unchanged.

    The resulting table must have NO row that contains the text "human" or "approval".
  </action>
  <verify>
    <automated>grep -n "human\|approval\|ask" /Users/p950cvo/Files/p-repositories/terraform-registry/SKILL.md && echo "FAIL — references remain" || echo "PASS — no human/approval references"</automated>
  </verify>
  <done>SKILL.md Section 3 table has zero rows containing "human", "approval", or "ask". All restricted operations now read "Freely — workflow checks must pass".</done>
</task>

<task type="auto">
  <name>Task 2: Update CLAUDE.md and STATE.md</name>
  <files>CLAUDE.md, .planning/STATE.md</files>
  <action>
    In CLAUDE.md, update the autonomy matrix bullet from:
      `- Autonomy matrix: what you can do freely vs. what requires human approval first`
    to:
      `- Autonomy matrix: what you can do freely — all operations proceed when workflow checks pass`

    In .planning/STATE.md, update the `[Init]` decision line from:
      `- [Init]: Mixed agent autonomy -- routine changes autonomous, breaking changes require human PR approval`
    to:
      `- [Init]: Full agent autonomy -- all operations proceed autonomously when workflow checks pass`
  </action>
  <verify>
    <automated>grep -n "human\|approval\|ask" /Users/p950cvo/Files/p-repositories/terraform-registry/CLAUDE.md /Users/p950cvo/Files/p-repositories/terraform-registry/.planning/STATE.md && echo "FAIL — references remain" || echo "PASS — no human/approval references"</automated>
  </verify>
  <done>Neither CLAUDE.md nor STATE.md contains any mention of human approval or asking for permission. STATE.md decision log reflects the updated policy.</done>
</task>

</tasks>

<verification>
grep -rn "human\|Must ask\|approval" \
  /Users/p950cvo/Files/p-repositories/terraform-registry/SKILL.md \
  /Users/p950cvo/Files/p-repositories/terraform-registry/CLAUDE.md \
  /Users/p950cvo/Files/p-repositories/terraform-registry/.planning/STATE.md

Expected: zero matches. Any match is a failure.
</verification>

<success_criteria>
All three files are free of "human", "Must ask", and "approval" language. Every autonomy row in SKILL.md reads "Freely — workflow checks must pass". CLAUDE.md bullet and STATE.md decision entry describe unconditional autonomy gated only on CI checks passing.
</success_criteria>

<output>
After completion, create `.planning/quick/1-we-can-remove-any-mention-of-requiring-h/1-SUMMARY.md`
</output>
