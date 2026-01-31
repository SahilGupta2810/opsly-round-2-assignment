## 🏗️ Multi-Account Structure with AWS Organizations or Control Tower

Use **AWS Organizations** or **AWS Control Tower** to create a secure, scalable multi-account setup. Control Tower simplifies setup with Account Factory, preconfigured guardrails, and centralized logging.

### Organizational Units (OUs) and Accounts
```
Root
├── Management OU
│   └── Management Account
├── Security OU
│   ├── Log Archive Account
│   └── Security Tooling Account
├── Shared Services OU
│   └── Shared Services Account
└── Application OU
    ├── Sandbox Account
    ├── Development Account
    ├── UAT Account
    └── Production Account
```

### Purpose of Each Account

| OU / Account            | Purpose                                                                 |
|------------------------|-------------------------------------------------------------------------|
| **Management Account**  | Billing, governance, Control Tower setup, SCP enforcement               |
| **Log Archive**         | Immutable storage for CloudTrail, Config, VPC Flow Logs                 |
| **Security Tooling**    | Aggregates findings from GuardDuty, Security Hub, Macie, Inspector      |
| **Shared Services**     | Hosts networking (VPCs, Transit Gateway), IAM Identity Center, backups  |
| **Sandbox**             | Free experimentation with relaxed guardrails                            |
| **Development**         | Active development, CI/CD pipelines                                     |
| **UAT**                 | Pre-production testing and validation                                   |
| **Production**          | Runs live workloads with strict security and monitoring                 |

---

## 🔐 Governance with SCPs (Service Control Policies)

SCPs enforce boundaries across accounts. They don’t grant permissions but restrict what’s allowed.

### Root-Level SCPs
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyIAMUserCreation",
      "Effect": "Deny",
      "Action": ["iam:CreateUser", "iam:DeleteUser"],
      "Resource": "*"
    },
    {
      "Sid": "RestrictRegions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1", "ap-south-1"]
        }
      }
    }
  ]
}
```

### Security OU SCPs
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOnlySecurityServices",
      "Effect": "Deny",
      "NotAction": [
        "guardduty:*", "securityhub:*", "macie:*", "cloudtrail:*", "config:*", "s3:*"
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

### Shared Services OU SCPs
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNetworkDeletion",
      "Effect": "Deny",
      "Action": [
        "ec2:DeleteVpc", "ec2:DeleteTransitGateway", "ec2:DeleteInternetGateway"
      ],
      "Resource": "*"
    }
  ]
}
```

### Application OU SCPs

**Production Account**
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

**Non-Production (Dev, UAT, Sandbox)**
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
      "Action": ["iam:CreateUser", "iam:DeleteUser"],
      "Resource": "*"
    }
  ]
}
```

---

## 👥 Access Management with AWS IAM Identity Center (SSO)

Use **IAM Identity Center** to manage access across accounts. Integrate with your identity provider (e.g., Azure AD, Okta) and assign permission sets based on team roles.

### Example Roles and Permissions

| Role             | Access Scope                                                   |
|------------------|----------------------------------------------------------------|
| **Developers**    | Full access in Dev, UAT, Sandbox; Read-only in Prod            |
| **Security Team** | Read-only across all accounts; Admin in Security OU            |
| **Ops Team**      | Admin in Shared Services and Monitoring accounts               |

- Use permission sets like `PowerUserAccess`, `ReadOnlyAccess`, or custom roles.
- Enforce **least privilege** and **break-glass roles** for emergency access in Prod.

---

## 🛡️ Centralized Security Services

Deploy these services in **Security OU** and **Shared Services OU**:

| Service         | Purpose                                                                 |
|----------------|-------------------------------------------------------------------------|
| **CloudTrail**   | Org-wide logging of API activity                                       |
| **AWS Config**   | Tracks resource changes and compliance                                 |
| **GuardDuty**    | Threat detection across accounts                                       |
| **Security Hub** | Aggregates findings from GuardDuty, Macie, Inspector                   |
| **Macie**        | Sensitive data discovery in S3                                         |
| **Inspector**    | Vulnerability scanning for EC2 and containers                          |
| **AWS Backup**   | Centralized backup policies and cross-account recovery                 |
| **KMS**          | Centralized encryption key management                                  |

Logs from all accounts should flow into the **Log Archive**, and findings into **Security Tooling**.

---
