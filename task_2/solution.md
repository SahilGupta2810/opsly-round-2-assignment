# AWS Account Structure & Security 
Your AWS environment is organized like a company with different departments. At the top is the **Root**, which sets rules that apply everywhere. Beneath it are **Organizational Units (OUs)**, each with a specific purpose. Some OUs focus on **security**, some on **infrastructure**, and others on **applications**.  

Central accounts act like “shared service hubs.” They don’t run applications themselves but provide logging, security, networking, monitoring, and backup so that every team works with consistent guardrails. This reduces risk, ensures compliance, and makes operations smoother.  

📖 Reference: [Foundational OUs – Organizing Your AWS Environment](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/foundational-ous.html)

---

## Organization Structure  
```
Root
├── Security OU
│   ├── Log Archive
│   └── Security Tooling
├── Infrastructure OU
└── Application OU
    ├── Production OU
    └── Non-Production OU
```

- **Root:** The top level. Rules here apply everywhere.  
- **Security OU:** Contains Log Archive and Security Tooling accounts. These are the “safety and compliance” departments.  
- **Infrastructure OU:** Provides shared networking and core services.  
- **Application OU:** Where teams run workloads. Split into Production (strict rules) and Non‑Production (more freedom for testing).  

---

## Security OU  

### Log Archive  
- **Purpose:** Collects all logs (like activity records) from every account.  
- **Why it matters:** Logs are the “black box recorder” of your cloud. They prove compliance, help in investigations, and protect against tampering.  
- **Controls:** Logs are stored in S3 with versioning, encryption, and strict rules to prevent deletion.  

📖 Reference: [Centralized Logging with CloudWatch](https://docs.aws.amazon.com/prescriptive-guidance/latest/implementing-logging-monitoring-cloudwatch/cloudwatch-centralized-distributed-accounts.html)  

**Sample SCP Policy (prevent log tampering):**  
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLogTampering",
      "Effect": "Deny",
      "Action": [
        "s3:DeleteBucket",
        "s3:DeleteObject",
        "cloudtrail:DeleteTrail",
        "cloudtrail:StopLogging"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### Security Tooling (Audit)  
- **Purpose:** Acts as the “security control room.”  
- **Why it matters:** Collects alerts from GuardDuty, Security Hub, Macie, Inspector, and more. Security teams use this account to investigate issues safely.  
- **Controls:** Only security services are allowed here. No application workloads.  

📖 Reference: [Get More Out of SCPs](https://aws.amazon.com/blogs/security/get-more-out-of-service-control-policies-in-a-multi-account-environment/)  

**Sample SCP Policy (restrict to security services):**  
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOnlySecurityServices",
      "Effect": "Deny",
      "NotAction": [
        "cloudtrail:*",
        "config:*",
        "guardduty:*",
        "securityhub:*",
        "macie:*",
        "inspector:*",
        "detective:*",
        "access-analyzer:*",
        "s3:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyOrgTampering",
      "Effect": "Deny",
      "Action": [
        "organizations:DeletePolicy",
        "organizations:DetachPolicy",
        "organizations:LeaveOrganization"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Infrastructure OU  
- **Purpose:** Provides shared networking services like VPCs, Transit Gateway, and DNS.  
- **Why it matters:** Ensures all accounts connect securely without duplicating networks.  
📖 Reference: [Networking for Multi‑AWS Accounts](https://aws.plainenglish.io/networking-for-multi-aws-accounts-ef4381bbd113)  

**Sample SCP Policy (protect networking):**  
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNetworkDeletion",
      "Effect": "Deny",
      "Action": [
        "ec2:DeleteVpc",
        "ec2:DeleteTransitGateway",
        "ec2:DeleteInternetGateway"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Application OU  

### Production OU  
- **Purpose:** Runs critical workloads.  
- **Controls:** Strict rules — enforce encryption, block risky services, prevent tampering with monitoring.  

**Sample SCP Policy (production guardrails):**  
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnapprovedRegions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1", "ap-south-1"]
        }
      }
    },
    {
      "Sid": "DenyDisableEncryption",
      "Effect": "Deny",
      "Action": [
        "ec2:DisableEbsEncryptionByDefault",
        "s3:PutBucketEncryption",
        "rds:ModifyDBInstance"
      ],
      "Resource": "*"
    }
  ]
}
```

---

### Non‑Production OU  
- **Purpose:** For testing and experimentation.  
- **Controls:** More freedom, but still block dangerous actions like disabling security or creating IAM users.  

**Sample SCP Policy (non‑production guardrails):**  
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenySecurityToolDisable",
      "Effect": "Deny",
      "Action": [
        "guardduty:DeleteDetector",
        "securityhub:DisableSecurityHub"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyIAMUserCreation",
      "Effect": "Deny",
      "Action": [
        "iam:CreateUser",
        "iam:DeleteUser"
      ],
      "Resource": "*"
    }
  ]
}
```

📖 Reference: [3 SCP Examples to Secure Accounts](https://dev.to/aws-builders/3-aws-service-control-policy-scp-examples-to-secure-your-accounts-14bl)  

---

## Example Flow  
- A Dev account runs workloads and generates logs.  
- Logs are sent to the **Log Archive** in the Security OU.  
- Security alerts go to the **Security Tooling** account.  
- Monitoring shows dashboards and alerts.  
- Network provides shared connectivity.  
- Operations tools run fixes across accounts.  

---