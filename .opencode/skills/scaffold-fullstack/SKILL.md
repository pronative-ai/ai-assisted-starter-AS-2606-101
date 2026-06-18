---
name: scaffold-fullstack
description: Scaffold a monorepo with .NET 10 WebAPI backend and Next.js (React) frontend, plus a CI workflow that builds both projects in parallel.
license: MIT
compatibility: opencode
metadata:
  domain: scaffolding
  stack: dotnet-nextjs
---

## Folder Structure

```
<project-root>/
├── src/
│   ├── frontend/          # Next.js UI application
│   └── backend/           # .NET 10 WebAPI
├── .github/
│   └── workflows/
│       └── ci.yaml        # CI pipeline (parallel jobs)
└── .gitignore
```

## Prerequisites

- .NET 10 SDK (`dotnet --list-sdks` to verify)
- Node.js 22+ and npm

## Steps

### 1. Create .gitignore

Write `.gitignore` at the project root covering dotnet (`bin/`, `obj/`), node (`node_modules/`, `.next/`), and OS files.

### 2. Scaffold backend

```
dotnet new webapi -n backend -o src/backend --no-https
```

Modify `src/backend/Program.cs`:
- Add CORS policy allowing frontend origin (`http://localhost:3000`)
- Keep `MapControllers()` or minimal API endpoints
- Remove HTTPS redirection
- Configure to listen on `http://localhost:5000`

Add a sample `Controllers/PingController.cs` if the template didn't scaffold one.

### 3. Scaffold frontend

```
npx --yes create-next-app@latest src/frontend --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --use-npm --no-turbopack
```

Create `src/frontend/.env.local`:
```
NEXT_PUBLIC_API_URL=http://localhost:5000
```

Update `src/frontend/src/app/page.tsx` to fetch data from the backend API as a demo.

### 4. Create CI workflow

Write `.github/workflows/ci.yaml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  DOTNET_VERSION: "10.0.x"
  NODE_VERSION: "22"

jobs:
  backend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: src/backend
    permissions:
      actions: read
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ env.DOTNET_VERSION }}

      # CodeQL scan
      - uses: github/codeql-action/init@v3
        with:
          languages: csharp
          queries: security-and-quality
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
        with:
          category: "code-scanning:backend"

      # Build & test
      - run: dotnet restore
      - run: dotnet build --no-restore --configuration Release
      - run: dotnet test --no-build --configuration Release

      # NuGet dependency vulnerability check
      - run: dotnet list package --vulnerable --output-format json

      # Secret scanning
      - name: Secret scanning
        uses: trufflesecurity/trufflehog@v3
        with:
          extra_args: --only-verified --results=verified

  frontend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: src/frontend
    permissions:
      actions: read
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: "npm"
          cache-dependency-path: src/frontend/package-lock.json

      # CodeQL scan
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript-typescript
          queries: security-and-quality
      - uses: github/codeql-action/autobuild@v3
      - uses: github/codeql-action/analyze@v3
        with:
          category: "code-scanning:frontend"

      # Build & test
      - run: npm ci
      - run: npm run build
      - run: npm test --if-present

      # npm dependency audit
      - run: npm audit --audit-level=high || true

      # Secret scanning
      - name: Secret scanning
        uses: trufflesecurity/trufflehog@v3
        with:
          extra_args: --only-verified --results=verified

  dependency-review:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: high
          comment-summary-in-pr: true
```

### 5. Root package.json (optional)

Offer the user a root `package.json` with convenience scripts:

```json
{
  "private": true,
  "scripts": {
    "dev": "concurrently \"npm run dev:backend\" \"npm run dev:frontend\"",
    "dev:backend": "dotnet run --project src/backend",
    "dev:frontend": "npm --prefix src/frontend run dev"
  },
  "devDependencies": {
    "concurrently": "^9.0.0"
  }
}
```

## Verification

- `dotnet build src/backend` — succeeds
- `npm --prefix src/frontend run build` — succeeds
- `.github/workflows/ci.yaml` exists with `backend`, `frontend`, and `dependency-review` jobs
- Each build job includes CodeQL scanning, dependency vulnerability check, and secret scanning

## Notes

- .NET 10 SDK must be installed locally
- The CI runs both jobs in parallel (they are independent)
- If the user wants a different port or CORS setup, adjust accordingly
