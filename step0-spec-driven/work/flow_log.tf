# -----------------------------------------------------------------------------
# CloudWatch Logs Group for VPC Flow Logs
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "flow_log" {
  name              = "/aws/vpc/flow-log/${var.project}-${var.env}"
  retention_in_days = 7

  tags = {
    Name = "${var.project}-${var.env}-flow-log"
  }
}

# -----------------------------------------------------------------------------
# IAM Role for VPC Flow Logs
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "flow_log_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc-flow-log/*"]
    }
  }
}

resource "aws_iam_role" "flow_log" {
  name               = "${var.project}-${var.env}-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role.json

  tags = {
    Name = "${var.project}-${var.env}-flow-log-role"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy for VPC Flow Logs (least privilege)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "flow_log_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      aws_cloudwatch_log_group.flow_log.arn,
      "${aws_cloudwatch_log_group.flow_log.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "flow_log" {
  name   = "${var.project}-${var.env}-flow-log-policy"
  role   = aws_iam_role.flow_log.id
  policy = data.aws_iam_policy_document.flow_log_permissions.json
}

# -----------------------------------------------------------------------------
# VPC Flow Log
# -----------------------------------------------------------------------------

resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type    = "ALL"

  tags = {
    Name = "${var.project}-${var.env}-flow-log"
  }
}
