# Paste into Lovable — finish the implemented publication-alert backend

Use the isolated implementation already built. Evaluate the concrete issues below,
choose practical fixes, implement and test them in that draft, and return the exact
updated contracts for native integration. Do not restart an audit or stop at a plan.

1. Make registration retry-safe after a lost 201 response. Currently the installation
   credential is returned once, so a request accepted by the server whose response
   is lost leaves a fresh app permanently receiving 409 without its credential.
   Implement secure recovery/idempotency with a device-held secret established
   before the first request, without enabling unauthenticated token takeover.
   Preserve existing successful clients and hash server-side credentials. Return
   the precise request/response changes and fixtures for timeout/retry/concurrency.
2. Enforce APNs' 64-byte collapse-ID limit, using a deterministic bounded hash when
   notification IDs exceed it. Validate payload/header limits before dispatch.
3. Protect rotated registrations from stale APNs invalidation responses: bind each
   send result to the token generation sent and apply Unregistered timestamps.
   Distinguish environment/topic/provider misconfiguration from a genuinely stale
   installation so one setup error cannot revoke the whole subscriber audience.
4. Make HTTP/2 capability explicit in the delivery gate and implement a supported
   transport on existing infrastructure if the runtime cannot negotiate it. Keep
   real delivery off. Return transport-level evidence without contacting real
   subscribers or creating a paid relay. Actual Apple delivery still needs owner
   authorization and securely configured APNs credentials.
5. Ensure the once-per-publication queue can run promptly, with reconciliation as
   a fallback, and that flipping upcoming state cannot skip an announcement. Bind
   editorial upcoming keys to the intended publication, avoiding an unrelated fair
   in the same city satisfying a Watches & Wonders/BWD announcement subscription.
6. Verify the signed-in unsubscribe/resubscribe flow end to end using isolated test
   data. Keep the newsletter sender explicitly unconfigured and send nothing.

Codex has implemented the native v1 adapter with both local and remote gates Off,
Keychain enrollment, unsubscribe retries, canonical-feed routing and optional
analytics kept separate. Keep these released-client constraints: non-null v1 string
slugs, stable IDs, TestFlight production APNs and no new login requirement.

Return only the working diff/commit, test results, changed API contract, exact
secure missing configuration, and a concise migration/deployment step with rollback.
No production deployment, shared-backend migration, dispatch schedule, real messages,
key rotation or expenditure is authorized. Implementation/tests in preview may proceed.
