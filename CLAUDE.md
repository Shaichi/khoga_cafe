# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Backend API for **Khoga Coffee Shop** — a multi-branch coffee-chain management system (POS, orders, inventory, staff, CRM, reporting). Built as a **modular monolith** following the COMET EBC (Entity–Boundary–Control) method.

**Current state:** Only the shared base framework exists today — the `com.khoga.common` (persistence) and `com.khoga.config` packages. The 18 feature subsystems described in the design docs (`auth`, `catalog`, `pos`, `order`, `inventory`, `staff`, `report`, etc.) are **not yet implemented**. Most work is building these feature packages on top of the existing entities/repositories.

## Tech Stack

- Java 21, Spring Boot **4.1.0** (note: the design docs say "3.x / Java 17" — the code is 4.1.0/21)
- Spring Data JPA, Spring WebMVC, Bean Validation, Thymeleaf, Lombok
- Microsoft SQL Server (mssql-jdbc)
- springdoc-openapi (Swagger UI) 2.5.0

Spring Boot 4.x uses **split starter names** — `spring-boot-starter-webmvc` (not `-web`) and per-starter `*-test` artifacts (`spring-boot-starter-webmvc-test`, etc.). Match this convention when adding dependencies.

## Environment setup (required — from README §1–§2)

These are hard prerequisites; the project will not build or run if they are unmet.

- **JDK 21 is mandatory.** `pom.xml` pins `<java.version>21</java.version>` and Spring Boot 4.1.0 requires Java 17+ — building on an older JDK fails. Before any Maven command, verify `./mvnw -version` reports `Java version: 21.x`; if not, install JDK 21 (`winget install Microsoft.OpenJDK.21`) and point `JAVA_HOME` at it.
  - ⚠️ **Verified on this machine (2026-06-21): only JDK/JRE 1.8.0_202 is installed and the Maven wrapper runs on Java 8** — `./mvnw clean package` will fail until JDK 21 is installed and active (`JAVA_HOME`/PATH). This is the current top blocker.
- **SQL Server must be running** with database `khoga_coffee_shop`, login `sa`, password `123`, reachable at `localhost:1433` — must match [application.properties](src/main/resources/application.properties).
  - ✅ Verified reachable: a SQL Server Express instance is up on `1433`, `sa`/`123` connects, and database `khoga_coffee_shop` already exists. (README suggests Developer Edition; Express works identically here.)
- **Always use the Maven wrapper** (`./mvnw` / `mvnw.cmd`) — it pins Maven 3.9.x; do not rely on a globally-installed `mvn`.

## Commands

Use the Maven wrapper. On Windows use `mvnw.cmd`; the examples below use the POSIX `./mvnw`.

```bash
./mvnw spring-boot:run            # run the app (http://localhost:8080)
./mvnw clean package              # build the jar
./mvnw test                       # run all tests
./mvnw test -Dtest=ClassName      # run a single test class
./mvnw test -Dtest=ClassName#method   # run a single test method
```

Swagger UI (live API docs) once running: **http://localhost:8080/swagger-ui.html**

### Database prerequisite

The app connects to a SQL Server database that must exist **before** first run (Hibernate creates the tables, not the database). Create it once:

```sql
CREATE DATABASE khoga_coffee_shop;
```

Connection + credentials live in [src/main/resources/application.properties](src/main/resources/application.properties). `spring.jpa.hibernate.ddl-auto=update` means **the schema is entity-driven** — Hibernate auto-generates/alters the 22 tables from the `@Entity` classes on startup. Changing an entity changes its table automatically; there are no migration scripts.

## Implementation decisions (locked)

Settled for the P0→P1 build; override later only with a clear reason:
- **JWT library**: `io.jsonwebtoken:jjwt` (explicit, simple) — not the OAuth2 resource server.
- **DTO ↔ entity mapping**: hand-written static mappers per feature; adopt MapStruct only if boilerplate becomes painful.
- **Logout / token**: stateless (client discards the token). Real server-side token invalidation (BR-18) is deferred to P4.
- **Test database**: integration tests run against the local SQL Server (already configured); add H2/Testcontainers only if fast isolated tests are needed.

## Architecture

The root package is **`com.khoga`** (the main class is `com.khoga.CoffeeshopApplication`). The design docs sometimes write `com.khoga.coffeeshop` — that is wrong; use `com.khoga`. Each feature subsystem is its own package directly under `com.khoga` (e.g. `com.khoga.auth`, `com.khoga.catalog`, `com.khoga.pos`).

**Shared Persistence Layer — `com.khoga.common`.** This is a deliberate, non-obvious design choice: **all** JPA entities and repositories live in `common`, shared by every feature, rather than each feature owning its own entities.
- `common/model/` — the 22 `@Entity` classes + `BaseEntity` (a `@MappedSuperclass`)
- `common/model/enums/` — status/type enums (persisted as strings)
- `common/repository/` — one Spring Data `JpaRepository` per entity
- `common/dto/` — `ApiResponse<T>` (the standard envelope)
- `common/exception/` — custom exceptions + `GlobalExceptionHandler`

When building a feature, **do not** create new entity classes inside the feature package — add the entity + its repository to `common`, then put the `@RestController` / `@Service` / business-rule `@Component` in the feature package.

**COMET EBC → Spring mapping** (how design-doc stereotypes become code):

| Stereotype | Spring implementation |
| --- | --- |
| «boundary» API endpoint | `@RestController` (all endpoints under `/api/v1/`) |
| «boundary» external proxy | `RestTemplate`/`WebClient` adapter (`com.khoga.integration`) |
| «control» coordinator | `@Service` with `@Transactional` |
| «application logic» engine | stateless `@Component` (e.g. discount/recipe-deduction engines) |
| «entity» domain object | `@Entity` + `@Repository` (in `common`) |
| «timer» scheduled task | `@Scheduled` (`com.khoga.scheduler`) |

`com.khoga.config` holds cross-cutting beans: `JpaConfig` (enables JPA auditing), `WebConfig` (CORS — currently open to all origins), `OpenApiConfig` (Swagger metadata).

Note: JWT auth / MFA appear throughout the design but **Spring Security is not yet a dependency** — auth is unimplemented.

## Mandatory conventions

These are enforced team rules; follow them in every feature:

1. **Always return `ApiResponse<T>` from controllers** — never a raw object/entity. Use the factory methods:
   ```java
   return ResponseEntity.ok(ApiResponse.success(data, "..."));
   return ResponseEntity.badRequest().body(ApiResponse.error("..."));
   ```

2. **Never write try-catch to produce error responses.** Throw a domain exception and let `GlobalExceptionHandler` map it:
   - `ResourceNotFoundException` → HTTP 404
   - `AppException` → HTTP 400 (business-rule failures)
   - any other exception → HTTP 500

3. **Every entity `extends BaseEntity`.** Never declare `createdAt` / `updatedAt` yourself — `BaseEntity` populates them via JPA auditing. Follow the existing entity pattern: UUID primary key (`@GeneratedValue(strategy = GenerationType.UUID)`) and enums mapped with `@Enumerated(EnumType.STRING)`.

## Design documentation

The `docs/` tree is the source of truth for *what* to build (entirely in Vietnamese):
- `docs/sections/` — User Requirements (URD): use cases (`UC-xx`) and business rules (`BR-xx`) per functional area.
- `docs/rds_sections/` — Requirements Design Spec (RDS): system architecture, package diagram, database design, and a detailed design file per subsystem.

Code and design reference features by `UC-xx` / `BR-xx` ids — when implementing a subsystem, find its detailed design in `docs/rds_sections/` and the matching requirements in `docs/sections/`.
