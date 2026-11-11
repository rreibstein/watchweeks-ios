> Historical implementation prompt. Superseded by the final recovery contract and
> Lovable's deployed-alert API report (24 backend tests). Native implementation
> uses client-generated durable credentials. Provider credentials are already in
> Lovable; do not ask Reed for them or repeat this implementation request. Next
> handoff is Reed's non-secret TestFlight installation ID for a selected-device
> provider test. Public activation waits for his physical-receipt confirmation.

# Paste into Lovable — launch publication alerts

Reed has published the implementation and authorized finishing the live feature.
Evaluate the concrete remaining issues, implement and test the fixes, and deploy
them to watchweeks.com. Do not restart an audit or stop at another preview/plan.
Verify that /api/public/guides/upcoming and /notify actually serve on that domain;
both still returned 404 to Codex after the reported publication. Ensure the formerly
isolated implementation, including its required migration, reached the real release.
Preserve all existing website features, authentication, synchronization and user data.

1. Make registration recover safely if the first successful response is lost.
   Current POST returns a once-only credential; a lost response leaves an app
   without it receiving 409. Implement secure retry/idempotency without token
   takeover. Preserve existing successful clients; return the updated native
   contract and timeout/concurrency fixtures.
2. Bound APNs collapse IDs to 64 bytes, hash longer notification IDs deterministically,
   and validate APNs payload/header limits. Do not revoke a rotated registration
   for an old token's response. Distinguish topic/environment/provider setup errors
   from real token expiration.
3. Verify HTTP/2 support in the deployed runtime and use a supported transport on
   existing infrastructure. Configure APNs through secure secret entry. If the key
   is missing, give Reed one precise Apple account action, never request private key
   contents in chat. No new expenditure is authorized.
4. Verify receipt on Reed's explicitly selected test installation before enabling
   public availability and scheduled publication alerts. TestFlight uses production
   APNs; development-entitled apps use sandbox. No historical-guide blast or test
   messages to unrelated subscribers. Keep capability false until receipt/transport
   are proven. Provide a stop switch and confirm current-guide baselines.
5. Verify signed-in newsletter unsubscribe/resubscribe against test data. Keep email
   sending off until an appropriate provider and suppression-aware delivery exist;
   do not promise a working mail service merely because /notify renders.

Codex is preparing a signed push-enabled native build: explicit opt-in, Keychain
enrollment, durable unsubscribe retry and safe canonical-guide routing. A TestFlight
verification path can enroll before public capability is On. App Store users remain
gated until delivery is proven. The app's optional analytics remains independent.

Return the final live endpoint schemas, changed native contract, deployment/test
results, capability state, exact secure missing setup and native integration details.
No unrelated production changes, key rotation, analytics identity joining, historical
messages or paid services.
