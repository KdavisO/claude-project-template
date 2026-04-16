# Copilot Review Instructions

## Role

This project uses Claude Code for implementation and self-review. Copilot serves as the final quality gate, focusing on areas that automated self-review may miss.

## Focus Areas (Priority Order)

### 1. Logic Correctness

- Edge cases: null/undefined, empty arrays/strings, boundary values (0, negative, max)
- Race conditions and concurrent access issues
- Off-by-one errors in loops and array indexing
- Incorrect boolean logic or missing conditions

### 2. Test Coverage

- Missing error/exception test cases
- Untested boundary values
- Mock objects that diverge from actual implementation behavior
- Assertions that don't verify the intended behavior

### 3. Design & Architecture

- Single Responsibility violations (functions/modules doing too much)
- Incorrect dependency direction (lower modules importing from higher ones)
- Overly broad public interfaces (exposing internal details)
- Unnecessary coupling between modules

### 4. Type Safety (TypeScript projects)

- Usage of `any` type (should use specific types or `unknown`)
- Missing or incorrect type annotations on public interfaces
- Type assertions (`as`) that may hide type errors
- Unsafe type narrowing without proper guards

### 5. Security

- OWASP Top 10 vulnerabilities (injection, XSS, broken auth, etc.)
- API key or secret exposure in code or config
- Missing input validation at system boundaries
- Insecure data handling (PII, encryption, RLS)

## Skip These

The following categories should NOT be flagged in reviews. The guiding principle: **skip stylistic preferences; flag only issues that affect correctness, security, or runtime behavior.**

### Formatting & Style

- Whitespace, indentation style, trailing commas, semicolons
- Import ordering or grouping
- Naming conventions (e.g., camelCase vs snake_case) — covered by self-review and linter
- Comment style, JSDoc completeness, or documentation wording
- Minor refactoring suggestions that don't affect correctness (e.g., "extract this into a helper")

### Document & Markdown Consistency

These are style preferences, NOT correctness issues:

- **Heading hierarchy variations**: e.g., a section using 4 subsections vs 5 subsections, or `###` vs `####` for similar content — these do not affect functionality
- **Reference path style mixing**: e.g., full path (`docs/specs/jwt-auth.md`) vs short name (`jwt-auth.md`) within the same document — both are valid if the target is unambiguous
- **Markdown formatting differences**: e.g., fenced code block style (`` ``` `` vs `~~~`), list marker style (`-` vs `*`), emphasis style (`**` vs `__`)

### Diff Display Artifacts

- **Escaped characters in diffs are NOT file content errors.** Git diff output may display escape sequences (e.g., `\"`, `\\n`) that do not exist in the actual file. Do not flag these as issues unless you have verified the raw file content contains the problematic escaping.
- Example false positive: a diff showing `{ \"key\": \"value\" }` — this is diff rendering, not a JSON escaping error in the source file

### Boundary: When Consistency IS a Valid Finding

Flag consistency issues ONLY when they cause one of the following:

- **Broken references**: a path, link, or cross-reference that points to a non-existent target
- **Contradictory statements**: two sections that make incompatible claims about the same behavior
- **Misleading examples**: a code example that would fail if copy-pasted (syntax errors, missing imports, wrong API usage)

## Commit Conventions

- Prefix required: `feat:`, `fix:`, `refactor:`, `ui:`, `docs:`, `chore:`, `test:`
- Japanese commit messages are acceptable
