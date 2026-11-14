## 1. Consolidate plugin ownership

- [x] 1.1 Record current regression suite results
- [x] 1.2 Move diff_tools modules into mini_diff
- [x] 1.3 Update plugin root references
- [x] 1.4 Verify merged runtime loads alone
- [x] 1.5 Remove obsolete diff_tools plugin root

## 2. Separate loaders and caches

- [x] 2.1 Extract shared refresh lifecycle coordination
- [x] 2.2 Introduce per-kind session cache modules
- [x] 2.3 Extract four hunk loader modules
- [x] 2.4 Adapt legacy engine snapshot APIs
- [x] 2.5 Verify independent cache mutation boundaries
- [x] 2.6 Verify stale snapshot rejection
- [x] 2.7 Verify saved baseline refresh behavior

## 3. Unify navigation ownership

- [x] 3.1 Extract four kind-specific navigation modules
- [x] 3.2 Introduce canonical global navigation rules
- [x] 3.3 Route movement through global navigation
- [x] 3.4 Route statusline through shared targets
- [x] 3.5 Verify saved unsaved cancellation semantics
- [x] 3.6 Verify overlapping target deduplication
- [x] 3.7 Verify repeat and handoff behavior

## 4. Separate hunk presentation modules

- [x] 4.1 Extract hunk rendering module
- [x] 4.2 Extract hunk preview module
- [x] 4.3 Extract hunk mode control module
- [x] 4.4 Delegate existing presentation entry points
- [x] 4.5 Verify gutter and overlay rendering
- [x] 4.6 Verify preview protection and cleanup
- [x] 4.7 Verify global toggle preference propagation
- [x] 4.8 Verify repeated presentation setup safety

## 5. Prove preserved behavior

- [x] 5.1 Verify callback ordering and readiness
- [x] 5.2 Verify untracked and ignored handling
- [x] 5.3 Verify preview and mutation safety
- [x] 5.4 Verify review and native navigation
- [x] 5.5 Run all diff regression suites
- [ ] 5.6 Check light and dark rendering
- [x] 5.7 Document single-root ownership and checks
