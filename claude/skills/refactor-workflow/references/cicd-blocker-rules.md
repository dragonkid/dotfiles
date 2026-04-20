# CI/CD BLOCKER Rules for Java Review

These rules are enforced by codemax bot on every PR. Violations at BLOCKER severity block merges. The reviewer should check for these patterns proactively — catching them before push saves a round-trip.

Source: https://git.toolsfdg.net/qa/cicd-policies (global-policies/global-rules.md)

---

## java:S2229 — @Transactional same-class call (BLOCKER)

Calling a `@Transactional` method from within the same class bypasses Spring's AOP proxy. The transaction annotation has no effect.

**Incompatible call patterns** (all are violations):
- Non-@Transactional → MANDATORY, NESTED, REQUIRED, REQUIRES_NEW
- REQUIRED → NESTED, NEVER, NOT_SUPPORTED, REQUIRES_NEW
- Any propagation → different propagation in same class

**Fix**: Extract the transactional method to a separate `@Service` class.

```java
// VIOLATION: same-class call bypasses proxy
public void process() {
    save();  // @Transactional ignored
}

@Transactional
public void save() { ... }

// FIX: inject a separate service
@Autowired
private SaveService saveService;

public void process() {
    saveService.save();  // proxy intercepts correctly
}
```

---

## java:S2168 — Double-checked locking (BLOCKER)

Double-checked locking with a non-volatile field is broken in Java. The JVM may reorder writes so another thread sees a partially constructed object.

**Fix**: Mark the field `volatile`, or use `enum` singleton / holder class pattern.

---

## java:S2068 — Hard-coded credentials (BLOCKER)

Passwords, API keys, tokens, or secrets must not appear as string literals. Applies to variable names containing: `password`, `passwd`, `secret`, `token`, `apikey`, `api_key`, `credential`.

**Fix**: Use environment variables, Apollo config, or a secrets manager.

---

## java:S2095 — Resources should be closed (BLOCKER)

`Closeable`/`AutoCloseable` resources (streams, connections, readers) must be closed, preferably via try-with-resources.

---

## java:S2189 — Infinite loops (BLOCKER)

Loops with no reachable `break`, `return`, or exception throw are flagged. Ensure all while/for loops have a termination condition that is reachable.

---

## java:P0002 — Thread pool unbounded queue (CRITICAL)

`ThreadPoolTaskExecutor` and `ExecutorService` created via `Executors.newFixedThreadPool()` must have a bounded queue. Default queue size is `Integer.MAX_VALUE` which can cause OOM.

**Fix**: Call `executor.setQueueCapacity(N)` with a reasonable bound.

---

## java:A0001 — System.getProperties() in concurrent code (CRITICAL)

`System.getProperties()` is synchronized internally. In high-concurrency code it becomes a bottleneck. Use `System.getProperty(key)` for individual values or cache the properties at startup.

---

## Redis pipeline async wrapping (CRITICAL)

`redisTemplate.executePipelined()` and `executeShardingRunPipelined()` must NOT be wrapped in `CompletableFuture.supplyAsync()`, `executor.submit()`, `@Async`, or any async construct. The pipeline is synchronous by design; async wrapping causes data inconsistency.

---

## java:S3305 — @Configuration factory method injection (CRITICAL)

In `@Configuration` classes, dependencies should be injected via method parameters (factory method injection), not via `@Autowired` fields. Spring's CGLIB proxy for `@Configuration` handles method-parameter injection correctly.

---

## Shutdown after submit (CRITICAL)

When `ExecutorService` is created locally in a method (via `Executors.newFixedThreadPool()`), it must be shut down in the same method after `submit()`/`execute()`. Does NOT apply to class-level executor fields.
