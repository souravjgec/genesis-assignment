## Entry 1

**Tool:** ChatGPT

**Part of assignment:** Part 1 – Creating Terraform modules

**What I asked:** I asked for help structuring the Terraform modules for compute, IAM, and observability so the stack would stay organized and reusable.

**What AI produced:** AI splitted the infrastructure into separate modules for Lambda compute, IAM roles/policies, and observability resources such as the log group, SNS topic, alarm, and dashboard.

**What I changed or verified:** I mapped the module inputs and outputs to the actual environment configuration and verified the final module wiring with Terraform and Checkov rather than relying only on the generated structure.

**Was the AI output correct?** Yes — the modular structure was a good design choice, although several implementation details still needed refinement during testing and deployment.

## Entry 2

**Tool:** ChatGPT

**Part of assignment:** Part 1 – Terraform hardening and Checkov remediation

**What I asked:** I asked for help fixing the remaining failed Checkov findings in the Terraform stack while keeping `CKV_AWS_117` intentionally skipped.

**What AI produced:** AI suggested adding KMS-backed encryption, DynamoDB point-in-time recovery, S3 lifecycle configuration, replication, notifications, Lambda DLQ support, tracing, and other Terraform changes across the environment and modules.

**What I changed or verified:** I reviewed the actual failed checks, matched each suggestion to the relevant Terraform resource, searched in google and understand checkov findings in details and reran Checkov repeatedly to confirm which changes really fixed findings and which ones introduced follow-on issues.

**Was the AI output correct?** Partially — the broad direction was correct, but several details needed adaptation to the exact Terraform layout and AWS behavior in this repo.

## Entry 3

**Tool:** ChatGPT

**Part of assignment:** Part 1 – Security tool configuration

**What I asked:** I asked for help making Checkov pass while preserving specific intentional design choices such as a non-VPC Lambda and public Function URL access.

**What AI produced:** AI proposed updating `.checkov.yml` with explicit skip entries and documenting the reason for each remaining exception.

**What I changed or verified:** I kept only the skips that matched deliberate design choices, removed temporary skips once the secret-manager resource was deleted, and added comments explaining why `CKV_AWS_117`, `CKV_AWS_115`, `CKV_AWS_258`, `CKV_AWS_301`, and `CKV_AWS_272` are still present.

**Was the AI output correct?** Yes — the approach was correct, but I still verified it by rerunning Checkov after every config change.

## Entry 4

**Tool:** ChatGPT

**Part of assignment:** Part 1 – Debugging incorrect AI output

**What I asked:** I asked for help fixing the secret-manager related Checkov findings and later the missing custom metric issue.

**What AI produced:** AI initially removed the placeholder Secrets Manager resource to make the secret-related Checkov findings disappear, and later assumed the custom metric path was already complete because the dashboard widget was configured.

**What I changed or verified:** I realized the deletion was the wrong fix when I explicitly said not to delete existing resources. The resource was then restored, and the approach was changed to preserve infrastructure unless removal was intentional. For the metric issue, I verified the dashboard query, IAM permission, and Lambda environment variables, then found that the application itself was no longer calling `PutMetricData` after the FastAPI/Mangum refactor, so I added that call explicitly.

**Was the AI output correct?** No for the initial secret-manager deletion approach, and Partially for the metric suggestion. Without checking against the intended infrastructure and the real application behavior, I would have removed a resource the project still wanted to keep and left the CloudWatch custom metric non-functional.

## Entry 5

**Tool:** ChatGPT

**Part of assignment:** Part 2 – FastAPI UI in Lambda

**What I asked:** I asked how to get the same UI in AWS that I see locally, including the FastAPI docs.

**What AI produced:** AI suggested serving the FastAPI app through Mangum, adding the dependency to the Lambda package, and switching the handler from the manual Lambda function to `main.handler`.

**What I changed or verified:** I added `mangum` to `app/requirements.txt`, updated `app/main.py`, changed the Terraform handler, and verified the tests still passed.

**Was the AI output correct?** Yes — the recommendation matched the current architecture and deployment workflow.

## Entry 6

**Tool:** ChatGPT

**Part of assignment:** Review of my own work

**What I asked:** I asked AI to review the IAM and Terraform changes while I was fixing Checkov findings and deployment failures, especially around Lambda permissions, KMS usage, and GitHub Actions role scope.

**What AI produced:** AI highlighted likely permission gaps, suggested ways to scope IAM statements, and helped reason about why some changes passed static checks but still failed at AWS apply time.

**What I changed or verified:** I did not trust the review blindly. I compared the suggestions against actual AWS errors, Terraform plan/apply output, and Checkov findings before deciding what to keep.

**Was the AI output correct?** Partially — it was useful as a review assistant, but the final decisions came from validating against live AWS behavior.

## Entry 7

**Tool:** ChatGPT

**Part of assignment:** Part 2 – API route behavior debugging

**What I asked:** I asked why `GET /items` returned `404` even though the API appeared to be deployed correctly.

**What AI produced:** AI explained that the application only implemented `POST /items` and `GET /items/{id}`, so `GET /items` would correctly return `404` until a list endpoint was added.

**What I changed or verified:** I reviewed the route definitions, added `GET /items`, updated the packaged Lambda code path so AWS used the same source as local development, and added a unit test for the list route.

**Was the AI output correct?** Yes — the diagnosis was accurate and led directly to the missing route implementation.

## Entry 8

**Tool:** ChatGPT

**Part of assignment:** Part 3 – Documentation for the alert runbook

**What I asked:** I asked for help creating the required Markdown runbook for the CloudWatch high-error-rate alarm.

**What AI produced:** AI drafted the structure for the runbook, including the alert meaning, likely causes, triage flow, a CloudWatch Logs Insights query, escalation guidance, and rollback steps.

**What I changed or verified:** I checked the Terraform alarm description to confirm the expected file path, verified that the runbook file was actually missing, and then committed the final version at `docs/runbooks/high-error-rate.md`.

**Was the AI output correct?** Yes — it matched the assignment requirements and only needed project-specific details and wording.

## Entry 9

**Tool:** ChatGPT

**Part of assignment:** Part 3 – SLO definition and rationale

**What I asked:** I asked for help drafting the required `slo/api-slo.yaml` and the written explanation for why a 99.0% target was chosen instead of 99.9%.

**What AI produced:** AI generated a starting YAML definition for the availability SLO and a rationale explaining that 99.0% is a more realistic target for a new internal Lambda-based API with limited historical data.

**What I changed or verified:** I filled in the actual owner name, kept the burn-rate field as a placeholder until enough production data exists, and reviewed the rationale against the current service maturity, monitoring setup, and deployment model.

**Was the AI output correct?** Yes — the draft was aligned with the prompt and only needed light context-specific edits.

## Entry 10

**Tool:** ChatGPT

**Part of assignment:** Part 2 – Creating the application

**What I asked:** I asked for help creating the FastAPI application structure for the assignment, including the health endpoint and item creation/retrieval behavior.

**What AI produced:** AI proposed the initial application shape with a FastAPI app, request validation using Pydantic, and routes for `/health`, `POST /items`, and `GET /items/{id}`.

**What I changed or verified:** I adapted the route behavior to the assignment requirements, added the `GET /items` route later when I noticed it was missing, and verified the final behavior with unit tests in `app/tests/test_main.py`.

**Was the AI output correct?** Partially — it provided a useful starting point, but I still had to review the route set, add missing behavior, and align the final implementation with the deployed Lambda flow.

## How AI Changed My Workflow on This Assignment

AI saved me the most time on repetitive but cognitively expensive tasks: generating first drafts of Terraform remediations, explaining why a particular Checkov control existed, outlining documentation, and suggesting likely causes for AWS errors. That speedup was real, especially when many small infrastructure concerns were interacting at once. The trade-off was that AI often produced something that was directionally right but not fully correct for this exact repo. The value came from using it as a fast collaborator, not as an unquestioned source of truth.

The clearest moment where AI was wrong was when it removed the placeholder Secrets Manager resource just to make the Checkov findings disappear. I spotted the problem when I reviewed the result in `terraform plan` result and realized it will delete the secret manager. Another important case was code signing: adding IAM permissions looked like the right fix at first, but the real deployment problem was that the workflow uploaded an unsigned zip while Lambda code signing enforcement was enabled. If I had shipped that unchecked, the deployment pipeline would still have failed even though the IAM policy looked more complete on paper. As a result, I documented the exception in .checkov.yml as an intentional development-stage trade-off for the current deployment workflow.

If I were onboarding a junior DevOps engineer, I would tell them to use AI as a draft generator, debugger, and reviewer, but never as the final authority. Ask it to propose options, explain errors, or structure docs, then verify every important change with the real system: `terraform plan`, `terraform apply`, tests, logs, dashboards, and scanner output. AI is most useful when paired with careful validation and an understanding of the actual runtime environment.
