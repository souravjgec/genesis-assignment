# Genesis Group DevSecOps Assignment

This repository contains the Part 1 foundation for the Genesis Group take-home assignment:

- A minimal FastAPI application with exactly three endpoints
- Intentional security flaws for pipeline demonstration
- GitHub Actions workflows for secure CI and gated deployment
- Developer tooling for local secret scanning and formatting

This repo is currently focused on Part 1 only: the application, the intentional flaws, and the secure CI pipeline.

## Repository Layout:

```text
app/
  main.py
  requirements.txt
  requirements-dev.txt
  Dockerfile
  tests/
.github/workflows/
  ci.yml
  deploy.yml
.semgrep/
  logging.yml
```

## Application Endpoints

- `GET /health` returns `{"status": "ok", "version": "1.0.0"}`
- `POST /items` creates an item in an in-memory store
- `GET /items/{id}` fetches an item by id or returns `404`

## Run Locally

1. Create a virtual environment and activate it.
2. Install dependencies:

```bash
pip install -r app/requirements-dev.txt
```

3. Start the API:

```bash
cd app
python main.py
```

4. Run tests:

```bash
PYTHONPATH=. pytest app/tests --cov=app --cov-report=term-missing --cov-fail-under=70
```

## Intentional Security Flaws

These are present on purpose for the first failed pipeline demonstration.

1. `app/main.py` contains a fake hardcoded secret:
   This should be blocked by Gitleaks.
2. `POST /items` logs the raw request body before sanitisation.
   This should be blocked by Semgrep using the custom rule in `.semgrep/logging.yml`.

After capturing the failed run evidence, the next step will be to remove both flaws and show the green pipeline.

## How The Pipeline Detects Them

### Gitleaks

Gitleaks scans the repository for hardcoded secrets and secret-like literals. The fake secret in `app/main.py` is intentionally written as an API key assignment so the secret scanning stage fails before dependency audit, SAST, build, or scan stages continue.

### Semgrep

Semgrep runs both the default community rules and the custom rule in `.semgrep/logging.yml`. The custom rule is broader than a single exact log line: it flags logging or printing variables commonly used for raw request data such as `raw_body`, `body`, `payload`, `request`, or `headers`.

That keeps the rule useful even if a developer introduces a similar unsafe logging pattern that is not identical to the assignment example.

## Local Developer Experience

Install `pre-commit` and enable hooks:

```bash
pip install pre-commit detect-secrets
pre-commit install
pre-commit run --all-files
```

The local hook uses `detect-secrets` so unsafe commits are caught before they reach CI.

## Pipeline Overview

### `ci.yml`

Runs on every pull request and every push to `main`.

1. Secret scan with Gitleaks
2. Dependency audit with `pip-audit`
3. SAST with Semgrep
4. Unit tests with coverage gate
5. Docker build with buildx
6. Trivy image scan
7. SBOM generation with Syft/Anchore SBOM action

Expected evidence flow for the assignment:

1. First failed run: Gitleaks blocks the hardcoded fake secret.
2. Second failed run after secret removal: Semgrep blocks the unsafe raw request logging.
3. Final green run after both fixes: all CI stages pass and artifacts are uploaded.

### `deploy.yml`

Runs only after a successful `main` branch CI workflow and is designed to:

1. Authenticate to AWS with GitHub OIDC
2. Package the Lambda artifact
3. Update the Lambda function
4. Run a smoke test against `/health`

This workflow expects Terraform-created AWS resources and GitHub repository secrets to be configured later in Part 2.

## Pipeline Design Decisions

1. Security gates run before build so we fail fast on secrets, vulnerable dependencies, or risky code without wasting runner time on Docker or deploy work.
2. Deploy is split into a dedicated workflow triggered from successful `main` CI runs, which keeps pull requests safe and makes the branch behavior explicit.
3. Scan outputs are uploaded as artifacts so the Trivy report, Semgrep SARIF, coverage XML, and SBOM remain available for audit evidence after the run completes.
4. The custom Semgrep rule is policy-oriented, not one-line-specific, so it can catch similar unsafe request-logging mistakes beyond the intentional example.
