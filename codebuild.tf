################################################################################
# CodeBuild Project
################################################################################

resource "aws_codebuild_project" "this" {
  name                   = var.application_name
  service_role           = aws_iam_role.codebuild.arn
  concurrent_build_limit = 1

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "${aws_ecr_repository.this.repository_url}:codebuild-image"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image_pull_credentials_type = "SERVICE_ROLE"
    privileged_mode             = false
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec.yaml")
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.this.name
      status     = "ENABLED"
    }
  }
}


################################################################################
# Cloudwatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name = "/aws/codebuild/${var.application_name}"

  retention_in_days = 30
}


################################################################################
# IAM Role for CodeBuild
################################################################################

resource "aws_iam_role" "codebuild" {
  name = "${var.application_name}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "codebuild" {

  statement {
    sid = "s3access"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
  }

  statement {
    sid = "codecommitaccess"
    actions = [
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:UploadArchive",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:CancelUploadArchive"
    ]

    resources = [aws_codecommit_repository.this.arn]
  }

  statement {
    sid = "snsaccess"
    actions = [
      "SNS:Publish"
    ]
    resources = [
      aws_sns_topic.this.arn
    ]
  }

  statement {
    sid = "kmsaccess"
    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.this.arn]
  }
}

resource "aws_iam_policy" "codebuild" {
  name   = "codebuild"
  policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild.arn
}

