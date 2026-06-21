---
name: test-data-factory
description: Generates realistic test fixtures, factories, and seed data for the current codebase's data models
tags: [testing, fixtures, factories, seed-data, mocks]
tools: Read, Grep, Glob, Bash, Write
---

# Test Data Factory

## When to Use
- Tests use `{}` or `null` as stand-ins for real data shapes
- Adding tests to a new model and need realistic fixtures
- Integration tests need consistent seed data
- E2E tests need a predictable database state to run against
- Test data is copy-pasted and drifting out of sync with the actual schema

## How It Works

1. **Discover data models** — find TypeScript interfaces, Prisma/Drizzle schemas, SQLAlchemy models, Pydantic models, or Zod schemas
2. **Infer field semantics** — `email` → realistic email format; `createdAt` → recent date; `userId` → valid UUID; `price` → numeric within realistic range
3. **Generate factory functions** — one factory per model with sensible defaults and override capability
4. **Generate relationship-aware fixtures** — if `Order` belongs to `User`, the Order factory creates or accepts a User
5. **Generate seed file** — a runnable seed script that populates a test database with a realistic minimum dataset
6. **Output files** — writes factory files to the project's test fixtures directory

## Quick Start
```
/test-data-factory
```
Target a specific model:
```
/test-data-factory User Order Product
```

## Generated Output

Given a Prisma schema with `User` and `Order`:
```typescript
// tests/factories/user.factory.ts
import { faker } from '@faker-js/faker'
import { User } from '@prisma/client'

export function createUser(overrides: Partial<User> = {}): User {
  return {
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    role: 'user',
    createdAt: faker.date.recent({ days: 30 }),
    updatedAt: new Date(),
    passwordHash: '$2b$10$placeholder',
    ...overrides,
  }
}

export function createAdminUser(overrides: Partial<User> = {}): User {
  return createUser({ role: 'admin', ...overrides })
}
```

```typescript
// tests/factories/order.factory.ts
export function createOrder(overrides: Partial<Order> & { userId?: string } = {}): Order {
  return {
    id: faker.string.uuid(),
    userId: overrides.userId ?? faker.string.uuid(),
    status: 'pending',
    totalCents: faker.number.int({ min: 100, max: 100000 }),
    currency: 'USD',
    createdAt: faker.date.recent({ days: 7 }),
    ...overrides,
  }
}
```

```typescript
// tests/seed.ts — runnable seed for integration/E2E tests
export async function seedTestDatabase(db: PrismaClient) {
  const admin = await db.user.create({ data: createUser({ role: 'admin' }) })
  const customers = await Promise.all(
    Array.from({ length: 5 }, () => db.user.create({ data: createUser() }))
  )
  for (const customer of customers) {
    await db.order.createMany({
      data: Array.from({ length: 3 }, () => createOrder({ userId: customer.id }))
    })
  }
}
```

## Rules Applied
- Factories never hit the database — they return plain objects
- All fields have realistic values (not `"string"` or `1`)
- Overrides are always last (spread pattern)
- Relationship fields accept an ID override or generate a valid-looking UUID
- No hardcoded IDs that conflict across tests

## Related Skills
- `tdd-enforcer` — use factories in TDD stubs
- `flaky-test-hunter` — shared factory state is a common flakiness cause
- `coverage-gap-analyzer` — identify which data paths lack test coverage
