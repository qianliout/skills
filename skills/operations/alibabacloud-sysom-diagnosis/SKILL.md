---
name: alibabacloud-sysom-diagnosis
description: |
  Use SysOM CLI and backend envelopes as the diagnosis source of truth.
  This Skill replaces the older SysOM diagnosis Skill and is the single entry
  point for SysOM ECS performance and stability diagnosis.
  Triggers: "SysOM", "OS诊断", "系统诊断", "deep diagnosis", "kernel",
  "OOM", "CPU high", "memory leak", "IO latency", "disk performance",
  "network jitter", "packet loss", "load spike", "system hang",
  "instance crash", "kernel oops", "kernel panic"
---

# alibabacloud-sysom-diagnosis

> **Skill Name**: alibabacloud-sysom-diagnosis
> **Goal**: Use SysOM CLI and backend envelopes as the diagnosis source of truth for Alibaba Cloud ECS performance and stability diagnosis.

---

## Immediate Route

When the user reports a symptom and has **not** provided fresh SysOM envelope output,
run the matching SysOM command from **Domain Routing** below **before** ad hoc Linux
inspection or manual probing. Then follow the returned `agent.summary`,
`agent.findings[].detail/category`, and `agent.next_steps[]`.

Raw Linux commands (via Cloud Assistant) are **bounded fallbacks** only when:
- A SysOM command is unavailable for the symptom domain
- SysOM outputs contradict each other
- A required entity remains missing after the focused SysOM command

---

## Credential Security

> **[CRITICAL] Credential Security Rules:**
> - **NEVER** print, echo, or display AccessKey ID / AccessKey Secret values in conversation or command output (even partial masking of `LTAI_ACCESS_KEY_ID` is FORBIDDEN)
> - **NEVER** ask the user to input AK/SK directly in the conversation or command line
> - **NEVER** use `aliyun configure set` with literal credential values
> - **ONLY** use `aliyun configure list` to check credential status
>
> ```bash
> aliyun configure list
> ```
> Check the output for a valid profile (AK, STS, or OAuth identity).
>
> **If no valid profile exists, STOP here.**
> 1. Obtain credentials from [Alibaba Cloud Console](https://ram.console.aliyun.com/manage/ak)
> 2. Configure credentials **outside of this session** (via `aliyun configure` in terminal or environment variables in shell profile)
> 3. Return and re-run after `aliyun configure list` shows a valid profile

---

## Prerequisites

> **Pre-check: Aliyun CLI >= 3.3.3 required**
> Run `aliyun version` to verify >= 3.3.3. If not installed or version too low,
> run `curl -fsSL https://aliyuncli.alicdn.com/setup.sh | bash` to install/update.

> **Pre-check: Aliyun CLI plugin update required**
> [MUST] run `aliyun configure set --auto-plugin-install true` to enable automatic plugin installation.
> [MUST] run `aliyun plugin update` to ensure that any existing plugins on your local machine are always up-to-date.

---

## Parameter Confirmation

> **IMPORTANT: Parameter Confirmation** — Before executing any command or API call,
> ALL user-customizable parameters (e.g., RegionId, InstanceId, time ranges)
> MUST be confirmed with the user. Do NOT assume or use default
> values without explicit user approval.

| Parameter | Required/Optional | Description | Default Value |
|-----------|-------------------|-------------|---------------|
| `region` | Required | Region where the ECS instance is located (e.g., `cn-hangzhou`) | None, must be provided by user |
| `instance_id` | Required | ECS instance ID to diagnose (`i-xxxxxxxxxxxxxxxxx`) | None, must be provided by user |
| `start_time` | Optional | Diagnosis start timestamp (Unix seconds) | `0` (real-time) |
| `end_time` | Optional | Diagnosis end timestamp (Unix seconds) | `0` |
| `enable_diagnosis` | Optional | Force real-time diagnosis (highest priority) | `false` |
| `ocd_description` | Optional | User's problem description in English, with words joined by underscores (`_`). No Chinese characters, no spaces. Example: `high_cpu_usage_oom_killed` | `None` |

### Time Inference Rule

When the user's description contains **any temporal reference** (e.g., "this morning", "yesterday afternoon", "around 3pm", "last night"), you **MUST** proactively ask for the specific time range and recommend **historical diagnosis mode**. Do NOT silently default to real-time diagnosis when the problem clearly occurred in the past.

| User Description | Inferred Action |
|-----------------|----------------|
| "The instance had OOM this morning" | Ask for specific time, recommend historical diagnosis |
| "Yesterday afternoon CPU spiked" | Ask for specific time window, recommend historical diagnosis |
| "The instance crashed around 3am" | Convert to Unix timestamps, recommend historical diagnosis |
| "CPU has been high for the past 2 hours" | Calculate `start_time = now - 2h`, recommend historical diagnosis |
| "The instance is slow right now" | Use real-time diagnosis (default) |

---

## Core Workflow

All `aliyun` CLI **business commands** (SysOM, ECS API calls) **MUST** include
`--user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis`.
System commands (`version`, `configure`, `plugin`) do NOT use `--user-agent`.

### Phase 1: Environment Setup (Steps 0–3)

**Step 0 — Enable AI-Mode and Update Plugins**

Before executing any CLI commands, enable AI-Mode, set User-Agent, and update plugins:

```bash
aliyun configure ai-mode enable
aliyun configure ai-mode set-user-agent --user-agent "AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis"
aliyun plugin update
```

> **⚠️ The above three commands must be executed before all CLI operations, and only need to be run once.**

**Step 1 — CLI Version Check**

```bash
aliyun version
```

Verify version >= 3.3.3. If not met, install/update via:
```bash
curl -fsSL https://aliyuncli.alicdn.com/setup.sh | bash
```

**Step 2 — Enable Auto Plugin Installation**

```bash
aliyun configure set --auto-plugin-install true
```

**Step 3 — Credential Verification**

```bash
aliyun configure list
```

If no valid credentials exist, **STOP** and guide the user to configure credentials outside the session.

---

### Phase 2: Resource Validation + Cloud Assistant Check (Steps 4–5)

**Step 4 — Ambiguous Problem Clarification (Inversion Gate)**

Must confirm `region`, `instance_id`, and **when the anomaly occurred**. If not provided by the user, ask explicitly.

If missing any required parameter, ask:

> 🔍 To perform SysOM deep diagnosis on ECS, I need to confirm the following:
>
> - **Instance ID**: Please provide the ECS instance ID (`i-xxxxxxxxxxxxxxxxx`)
> - **Region**: The Alibaba Cloud region where the instance is located (e.g., `cn-hangzhou`, `cn-beijing`, `cn-shanghai`)
> - **When did the anomaly occur?**: Is the issue happening right now, or did it occur at a specific time in the past? (This determines whether to use real-time or historical diagnosis mode)

**Step 5 — Instance Validation + Cloud Assistant Check**

#### 5A. Verify Instance Exists

```bash
aliyun ecs describe-instances \
  --region-id <region> \
  --instance-ids '["<instance_id>"]' \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

If the instance does not exist or is not found, inform the user and **STOP**.

#### 5B. Check Cloud Assistant Status

SysOM ECS diagnosis requires Cloud Assistant to be running on the instance.

```bash
aliyun ecs describe-cloud-assistant-status \
  --region-id <region> \
  --instance-id.1 <instance_id> \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

Check the response:
- `CloudAssistantStatus` is `true` → Cloud Assistant is installed and running, proceed to Step 6
- `CloudAssistantStatus` is `false` → Cloud Assistant is not installed or not running

If Cloud Assistant is not running, inform the user and **STOP**:

> ⚠️ Cloud Assistant is not running on instance `<instance_id>`. SysOM diagnosis requires Cloud Assistant to be active.
> Please install or start Cloud Assistant on the instance, then retry.
> See: https://www.alibabacloud.com/help/ecs/user-guide/cloud-assistant-overview

---

### Phase 3: Domain Routing & Diagnosis (Steps 6–8)

**Step 6 — Domain Routing: Map Symptom to SysOM Diagnostic Command**

Based on the user's problem description, route to the appropriate SysOM diagnostic
subsystem. See the **Domain Routing Table** below.

**Domain Routing Table:**

| Symptom Domain | Trigger Keywords | SysOM Diagnostic Scope | SysOM Subsystem |
|---------------|------------------|----------------------|-----------------|
| **CPU** | "CPU high", "CPU spike", "CPU 100%", "cpu utilization", "CPU steal", "CPU saturation" | User/kernel CPU usage, CPU saturation, scheduling latency | `cpu`, `scheduling` |
| **Memory** | "OOM", "out of memory", "memory leak", "memory high", "memory usage", "process killed", "oom killer" | Memory panoramic analysis, memory leak detection, OOM root cause | `memgraph`, `oom` |
| **IO / Disk** | "IO high", "iowait", "disk slow", "disk latency", "IOPS", "disk throughput", "fsync slow" | IO traffic attribution, IO latency, iowait root cause | `iofsstat`, `iodiagnose` |
| **Network** | "packet loss", "network jitter", "network latency", "TCP retransmit", "bandwidth", "connection timeout", "丢包", "网络抖动" | Packet drop analysis, network jitter, TCP anomalies | `packetdrop`, `netjitter` |
| **System Load** | "load high", "load average", "system hang", "unresponsive", "load spike", "LA high" | System load anomaly, load jitter, D-state process analysis | `loadtask` |
| **Kernel / Stability** | "kernel oops", "kernel panic", "crash", "hung task", "soft lockup", "hard lockup", "RCU stall", "kernel bug" | Kernel crash analysis, hung task detection | `hungtask`, `kerneldiag` |
| **Scheduling** | "scheduling delay", "latency spike", "RT throttling", "cgroup throttle" | CPU scheduling jitter, scheduling latency analysis | `delay`, `scheduling` |
| **General / Unknown** | Vague symptoms, "system slow", "performance degradation" | Full-system health check (all subsystems) | `healthy_score`, `full` |

> **IMPORTANT: Run the matching SysOM command BEFORE any ad-hoc Linux inspection or manual probing.**
> The SysOM envelope output provides `agent.summary`, `agent.findings[].detail/category`, and
> `agent.next_steps[]` — follow these as the primary diagnosis path.

#### SysOM Diagnosis Envelope Commands

Each domain has a corresponding SysOM diagnosis invocation. Build the params JSON with:

- **Real-time diagnosis**: `start_time=0`, `end_time=0`
- **Historical diagnosis**: `start_time=<unix_ts>`, `end_time=<unix_ts>`
- **Forced real-time** (`enable_diagnosis=true`): force `start_time` to `0` even if provided

**6A. CPU Diagnosis**

```bash
aliyun sysom invoke-diagnosis \
  --service-name ocd \
  --channel ecs \
  --params '{"instance_id":"<instance_id>","region":"<region>","start_time":0,"end_time":0,"type":"ocd","ai_roadmap":true,"enable_sysom_link":false,"subsystem":"cpu"}' \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

**6B. Memory / OOM Diagnosis**

```bash
aliyun sysom invoke-diagnosis \
  --service-name ocd \
  --channel ecs \
  --params '{"instance_id":"<instance_id>","region":"<region>","start_time":0,"end_time":0,"type":"ocd","ai_roadmap":true,"enable_sysom_link":false,"subsystem":"memgraph"}' \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

**6C. IO / Disk Diagnosis**

```bash
aliyun sysom invoke-diagnosis \
  --service-name ocd \
  --channel ecs \
  --params '{"instance_id":"<instance_id>","region":"<region>","start_time":0,"end_time":0,"type":"ocd","ai_roadmap":true,"enable_sysom_link":false,"subsystem":"iodiagnose"}' \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

**6D. Network Diagnosis**

```bash
aliyun sysom invoke-diagnosis \
  --service-name ocd \
  --channel ecs \
  --params '{"instance_id":"<instance_id>","region":"<region>","start_time":0,"end_time":0,"type":"ocd","ai_roadmap":true,"enable_sysom_link":false,"subsystem":"packetdrop"}' \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

**6E. System Load Diagnosis**

```bash
aliyun sysom invoke-diagnosis \
  --service-name ocd \
  --channel ecs \
  --params '{"instance_id":"<instance_id>","region":"<region>","start_time":0,"end_time":0,"type":"ocd","ai_roadmap":true,"enable_sysom_link":false,"subsystem":"loadtask"}' \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

**6F. Kernel / Stability Diagnosis**

```bash
aliyun sysom invoke-diagnosis \
  --service-name ocd \
  --channel ecs \
  --params '{"instance_id":"<instance_id>","region":"<region>","start_time":0,"end_time":0,"type":"ocd","ai_roadmap":true,"enable_sysom_link":false,"subsystem":"kerneldiag"}' \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

**6G. Full-System Health Check (General / Unknown Symptoms)**

```bash
aliyun sysom invoke-diagnosis \
  --service-name ocd \
  --channel ecs \
  --params '{"instance_id":"<instance_id>","region":"<region>","start_time":0,"end_time":0,"type":"ocd","ai_roadmap":true,"enable_sysom_link":false,"subsystem":"full"}' \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

> **Conditional params**: Add to JSON only when non-empty:
> - `"ocd_description": "<string>"` — user's problem description in English with underscores

Extract `task_id` from the response.

> **⚠️ [CRITICAL] `Sysom.TaskInProgress` Error Handling:**
> If `invoke-diagnosis` returns a `Sysom.TaskInProgress` error, this means a diagnosis task is already running. You **MUST**:
> 1. Extract the existing `task_id` from the error message using string match (pattern: `ocd(<task_id>)` or similar identifier in the message body)
> 2. Immediately proceed to the polling flow with the extracted `task_id`
> 3. **NEVER** treat `TaskInProgress` as a fatal failure or abort the workflow

---

**Step 7 — Poll Diagnosis Results**

Interval: 10 seconds, max 60 attempts (10 minutes total):

```bash
aliyun sysom get-diagnosis-result \
  --task-id <task_id> \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

Check the `status` field in the response:
- `Ready` / `Running` → **MUST** continue polling at 10s intervals
- `Success` → diagnosis complete, proceed to Step 8
- `Fail` → diagnosis failed, inform the user

> **⛔ [CRITICAL] Mandatory Polling Rules (MUST OBEY — violations will produce incorrect results):**
>
> **Rule 1: `Running` status is NORMAL — keep polling.**
> The diagnosis engine typically takes 1–5 minutes to complete. Receiving multiple consecutive `Running` responses is expected behavior. You **MUST** continue polling every 10 seconds without hesitation. `Running` is NOT an error and MUST NOT trigger early termination.
>
> **Rule 2: NEVER abandon polling early.**
> Do NOT stop polling before reaching `Success`, `Fail`, or the 60-attempt limit. Do NOT "give up" after a few `Running` responses.
>
> **Rule 3: NEVER fall back to manual Linux commands during polling.**
> Raw Linux commands via Cloud Assistant are **bounded fallbacks** only after diagnosis completes or when a SysOM command is unavailable for the symptom domain. During active polling, you MUST NOT run ad-hoc commands.
>
> **Rule 4: NEVER fabricate diagnosis results.**
> If the task has not reached `Success` status, you MUST NOT output any `summary.overall_status`, `summary.root_cause`, or `summary.suggestions` values. These fields come **exclusively** from the completed diagnosis result JSON.
>
> **Timeout handling**: If still incomplete after 60 polling attempts, output ONLY this template and stop:
>
> ```
> ⏳ SysOM diagnosis task timed out
> - Task ID: <task_id>
> - Current status: <status>
> - Suggestion: Please continue waiting for the diagnosis to complete.
> ```

---

**Step 8 — Result Parsing and Output**

Parse the returned JSON and present to the user:

| Field | Meaning | How Agent Should Use It |
|-------|---------|------------------------|
| `agent.summary` | SysOM overall summary | Present as the primary diagnosis conclusion |
| `agent.findings[].detail` | Detailed finding per subsystem | Present specific evidence for each issue |
| `agent.findings[].category` | Category of each finding (CPU/Memory/IO/Network/Kernel) | Group findings by subsystem |
| `agent.next_steps[]` | SysOM-recommended next actions | Incorporate into remediation recommendations |
| `summary.overall_status` | Overall status (Info/Warn/Critical) | Determine problem severity |
| `summary.root_cause` | SysOM root cause analysis | Kernel-level / runtime root cause evidence |
| `summary.suggestions` | Remediation suggestion list | Present directly to user |

---

### Phase 4: Bounded Fallback — Raw Linux Commands (Only When Applicable)

Raw Linux commands via Cloud Assistant are **bounded fallbacks** only when:
1. A SysOM command is unavailable for the symptom domain
2. SysOM outputs contradict each other (rare)
3. A required entity remains missing after the focused SysOM command

**When a fallback is warranted:**

```bash
# Execute a targeted command via Cloud Assistant
aliyun ecs run-command \
  --biz-region-id <region> \
  --instance-id.1 <instance_id> \
  --type RunShellScript \
  --command-content "$(echo '<linux_command>' | base64)" \
  --timeout 60 \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis

# Query results
aliyun ecs describe-invocation-results \
  --biz-region-id <region> \
  --invoke-id <invoke_id> \
  --user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis
```

> **Note:** The `Output` field in `describe-invocation-results` is Base64 encoded. Decode before analysis.

**DO NOT** use raw Linux commands as the primary diagnosis path when a matching SysOM command exists in the Domain Routing Table.

---

## SysOM Diagnosis Capability Coverage on ECS

| Subsystem | Diagnostic Tool | Diagnostic Content |
|-----------|----------------|-------------------|
| CPU | cpu, scheduling | User-space/kernel-space CPU usage, CPU saturation, scheduling latency |
| Memory | memgraph, oom | Memory panoramic analysis, memory leak detection, OOM root cause |
| IO | iofsstat, iodiagnose | IO traffic attribution, IO latency, iowait analysis |
| Network | packetdrop, netjitter | Packet loss, network jitter, TCP anomalies |
| Load | loadtask | System load anomaly, load jitter, D-state process analysis |
| Scheduling | delay | CPU scheduling jitter, scheduling latency |
| Kernel | hungtask, kernelevent | Hung task detection, kernel crash/oops/panic analysis |
| Health | healthy_score | Overall instance health scoring |

---

## Cleanup

**[MUST] Disable AI-Mode at EVERY exit point** — Before delivering the final response for ANY reason, always disable AI-mode first.

```bash
aliyun configure ai-mode disable
```

The diagnosis operations in this skill are **read-only** and do not modify the ECS instance state — no cleanup is needed.

---

## Error Handling

| Error Scenario | CLI Response | Agent Action |
|---------------|-------------|--------------|
| Invalid Instance ID | `DescribeInstances` returns empty | Inform user the instance ID does not exist in the region, stop pipeline |
| Cloud Assistant not running | `CloudAssistantStatus` is `false` | Inform user to install/start Cloud Assistant, stop pipeline |
| Role authorization failure | `initial-sysom` returns error | Prompt user to check SysOM service activation status |
| Diagnosis invocation failure | `invoke-diagnosis` returns error | Check credential, permission, and params JSON correctness |
| `Sysom.TaskInProgress` | Error with existing task_id | Extract task_id from error, proceed to polling |
| Diagnosis timeout | 60 polling attempts reached | Output timeout template, suggest user retry later |
| Insufficient permissions | API returns Forbidden | Guide user to grant required permissions |
| Instance OS not supported | Diagnosis returns unsupported OS | Inform user which OS versions are supported |

---

## Best Practices

1. **SysOM first, Linux second** — Always run the matching SysOM command from Domain Routing before ad-hoc inspection
2. **Follow the envelope** — `agent.summary`, `agent.findings[]`, and `agent.next_steps[]` are the primary diagnosis path
3. **Cloud Assistant is mandatory** — Check Cloud Assistant status before invoking diagnosis
4. **Real-time by default** — Unless the user specifies a historical time range, default to real-time diagnosis
5. **Credential security** — Never print or echo AK/SK values in conversation
6. **All business CLI commands must include `--user-agent AlibabaCloud-Agent-Skills/alibabacloud-sysom-diagnosis`**
7. **Never fabricate results** — All diagnosis conclusions must come from completed SysOM output
8. **One subsystem at a time** — Run the most relevant diagnostic first; expand to `full` only if the initial diagnosis is inconclusive
9. **Raw Linux commands are bounded fallbacks** — Only use when SysOM is unavailable, outputs contradict, or required entity is missing
