# Milestone coverage vs. GitHub tags

Upstream jdtls publishes prebuilt binaries only under
<https://download.eclipse.org/jdtls/milestones/>. Not every Git tag in
[eclipse-jdtls/eclipse.jdt.ls](https://github.com/eclipse-jdtls/eclipse.jdt.ls)
has a corresponding milestone directory, so the set of versions installable
*without* a local JDK + Maven build is smaller than the set of released tags.

Snapshot: **2026-07-26**. Derived from the GitHub tags API (139 unique
version-shaped tags, `v` prefix stripped) and the milestone directory listing
(128 entries). Re-verify before relying on it; upstream may backfill.

## Summary

| Set | Count |
| --- | ----- |
| Version-shaped Git tags | 139 |
| Milestone directories | 128 |
| Tags with **no** milestone | 11 |
| Milestones with **no** tag | 0 |

## Tags with no milestone build

```
0.20.1  0.30.0b  0.44.0  0.45.0  0.46.0  0.49.0
0.49.1  0.51.0   0.52.1  0.58.0  1.59.0
```

Ten of the eleven are pre-1.0 releases from 2017-2020. **`1.59.0` is the only
gap in the currently relevant range** — it sits between 1.58.0 (2026-04-15) and
1.60.0 (2026-06-26), both of which have milestones.

## Milestones with no tag

None. The milestone set is a strict subset of the tag set, which means any
version discovered by listing the milestone directory is guaranteed to
correspond to a real upstream release. Listing milestones is therefore a safe
and self-sufficient source for `Available`.

## Consequences for this plugin

- Supporting **only** milestone binaries costs exactly one useful version
  (`1.59.0`). Users who need it can install 1.60.0 instead.
- Because milestones are a subset of tags, `Available` can enumerate the
  milestone directory alone without cross-checking GitHub. That removes the
  paginated tags API call (two requests, 140 tags) from the hot path.
- The pre-1.0 gaps are not worth closing via source builds: those are Tycho
  builds pinned to Eclipse p2 repositories from 2017-2020, which are unlikely
  to still resolve, and they require contemporaneous JDKs.

## How this was derived

Both inputs were captured by hand:

- Tags: `mise ls-remote eclipse-jdtls` (the plugin's `Available` hook, which
  strips the `v` prefix).
- Milestones: the HTML directory index at
  <https://download.eclipse.org/jdtls/milestones/>.

To regenerate the comparison, save each list one-per-line and run:

```sh
sort -u tags.txt > t.s
sort -u milestones.txt > m.s
comm -23 t.s m.s   # tags with no milestone
comm -13 t.s m.s   # milestones with no tag
```

Note that `0.30.0b` is not valid semver and will not parse with the `semver`
Lua module; any version filtering needs to tolerate or exclude it.
