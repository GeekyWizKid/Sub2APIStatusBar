# Product Review

## Release Readiness Work

1. App identity
   - Added a custom app icon and bundle metadata.
   - Added release version wiring through build scripts.

2. Build and distribution
   - Added reproducible `.app` generation.
   - Added zip packaging and SHA-256 checksum output.
   - Added ad-hoc signing by default and Developer ID signing hooks.

3. GitHub delivery
   - Added CI for tests, debug build, packaged release artifact, and checksum.
   - Kept generated build outputs out of git.

4. User experience
   - Kept the app user-account focused.
   - Improved metric cards with icons and color grouping.
   - Reworked subscription quotas into daily, weekly, and monthly rows.
   - Clarified warning labels so quota pressure is not shown as a generic app error.

5. Reliability
   - Added tests for user dashboard payloads, balance decoding, quota progress, and status labels.
   - Preserved local config compatibility and user-only mode migration.

6. Documentation
   - Rewrote README as a product introduction and setup guide.
   - Added a changelog and release checklist.

## Remaining Product Work

The only meaningful blockers for public distribution are external materials:

- Apple Developer ID certificate for trusted signing.
- Apple notarization credentials.
- Product screenshots or a demo GIF captured from the final running app.
- A decision on whether the GitHub repository should stay private or become public.
