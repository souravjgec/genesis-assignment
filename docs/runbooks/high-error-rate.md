# High Error Rate Runbook

## Alert

**Alarm name:** `genesis-api-dev-high-error-rate`

**What it means:** The Lambda-backed API is returning errors for more than 5% of requests over a 5-minute window. In plain English, too many requests are failing and users may be unable to create or fetch items reliably.

## Likely Causes

1. A bad deploy introduced an application bug or packaging issue.
2. A downstream AWS dependency is failing, such as CloudWatch metric publishing or parameter/KMS access.
3. Malformed or unexpected client input is triggering unhandled exceptions.
4. The Lambda configuration changed incorrectly, such as handler, environment variables, or IAM permissions.
5. A transient AWS service issue or throttling event is affecting the function.

## Triage Steps

### 1. Confirm the alarm and blast radius

Check the CloudWatch alarm graph and confirm:

- error rate is above 5%
- invocations are non-zero
- whether this is a brief spike or sustained failure

Then check the API manually:

```bash
curl -i "$API_BASE_URL/health"
curl -i "$API_BASE_URL/items"
```

### 2. Inspect Lambda logs first

Open the Lambda log group:

- `/aws/lambda/genesis-api-dev`

Run this CloudWatch Logs Insights query:

```sql
fields @timestamp, @message
| filter @message like /ERROR|Exception|Traceback|Task timed out|REPORT/
| sort @timestamp desc
| limit 100
```

Look for:

- Python tracebacks
- permission failures
- handler/import errors
- timeout messages
- packaging or dependency import failures

### 3. Check recent deployment/config changes

Verify:

- latest GitHub Actions deployment status
- whether `main` was deployed recently
- Lambda configuration values such as handler, memory, timeout, and environment variables

If the issue started immediately after a deploy, suspect the new version first.

### 4. Check AWS Lambda metrics

Review these CloudWatch metrics for the same time window:

- `Errors`
- `Invocations`
- `Duration`
- `Throttles`

If throttles or duration spiked, the issue may be resource/config related rather than application logic.

### 5. Validate dependency access

If logs suggest AWS access issues, verify:

- IAM role permissions
- KMS decrypt access
- SSM parameter access
- CloudWatch `PutMetricData` access

## Escalation Path

If you cannot resolve the issue within **15 minutes**:

1. Notify the on-call engineer or project owner or team lead immediately.
2. Post in the team incident channel with:
   - alarm name
   - start time
   - impact summary
   - suspected cause
   - actions already taken
3. If customer impact is ongoing, escalate to the engineering lead and incident commander by Slack and phone.

For this project, notify:

- **Primary:** Sourav Sarkar via Slack/direct message
- **Fallback:** engineering lead/on-call contact via phone or incident channel

## Rollback Procedure

If the current Lambda version is broken, revert to the previous published version.

### Using the AWS Console

1. Open the Lambda function `genesis-api-dev`
2. Go to the **Versions** tab
3. Identify the last known good published version
4. Update the active alias or switch traffic back to that version

### Using AWS CLI

List versions:

```bash
aws lambda list-versions-by-function --function-name genesis-api-dev
```

Update the alias to the last known good version:

```bash
aws lambda update-alias \
  --function-name genesis-api-dev \
  --name live \
  --function-version <previous-good-version>
```

If aliases are not being used yet, redeploy the last known good artifact from GitHub Actions or the previous successful build artifact.

## Recovery Criteria

The incident is considered mitigated when:

- alarm returns to `OK`
- `/health` succeeds
- `/items` requests succeed normally
- Lambda error rate remains below 5% for at least 15 minutes
