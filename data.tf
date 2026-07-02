# ── Account identity ──────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {}

# ── KMS key policy ────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "kms" {
  statement {
    sid    = "AllowAccountRoot"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # DMS requires these to encrypt replication instance storage
  statement {
    sid    = "AllowDMS"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["dms.amazonaws.com"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

# ── VPC private subnets (looked up by tag after network module creates them) ──
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [module.network.vpc_id]
  }
  tags = {
    Type = "private"
  }

  depends_on = [module.network]
}
