resource "aws_iam_role" "codebuild_service_role" {
  name = "codebuild_service_role"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Service" = "codebuild.amazonaws.com"
        }
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_service_role" {
  name = "ecs_task_service_role"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Service" = "ecs-tasks.amazonaws.com"
        }
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_excecution_role" {
  name = "ecs_task_excecution_role"

  assume_role_policy = jsonencode({
    "Version" = "2008-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Service" = ["ecs-tasks.amazonaws.com"]
        }
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "codepipeline_service_role" {
  name = "codepipeline_service_role"

  assume_role_policy = jsonencode({
    "Version" = "2008-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Service" = "codepipeline.amazonaws.com"
        }
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role" "codedeploy_service_role" {
  name = "codedeploy_service_role"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Principal" = {
          "Service" = "codedeploy.amazonaws.com"
        }
        "Action" = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy_service_role.name
}

resource "aws_iam_role_policy" "codebuild_base_policy" {
  role = aws_iam_role.codebuild_service_role.name

  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Resource" = [
          "*"
        ]
        "Action" = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecs:DescribeTaskDefinition"
        ]
      },
      {
        "Effect" = "Allow"
        "Resource" = [
          "${aws_s3_bucket.codepipeline_bucket.arn}",
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
        "Action" = [
          "s3:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAccess" {
  role       = aws_iam_role.codebuild_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy" "codepipeline-base-policy" {
  role = aws_iam_role.codepipeline_service_role.name

  policy = jsonencode({
    "Version" = "2012-10-17"
    "Statement" = [
      {
        "Effect" = "Allow"
        "Action" = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
        ]
        "Resource" = [
          "${aws_s3_bucket.codepipeline_bucket.arn}",
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
      },
      {
        "Effect" = "Allow"
        "Action" = [
          "codebuild:BatchGetBuildBatches",
          "sns:*",
          "codecommit:UploadArchive",
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetDeploymentConfig",
          "elasticloadbalancing:*",
          "codecommit:CancelUploadArchive",
          "codebuild:BatchGetBuilds",
          "codecommit:GetCommit",
          "codecommit:GetUploadArchiveStatus",
          "cloudwatch:*",
          "codecommit:GetRepository",
          "codebuild:StartBuildBatch",
          "codecommit:GetBranch",
          "codedeploy:GetDeployment",
          "ecs:*",
          "ecr:*",
          "codebuild:StartBuild",
          "codedeploy:GetApplication",
        ]
        "Resource" = "*"
      },
      {
        "Effect"   = "Allow"
        "Action"   = "iam:PassRole"
        "Resource" = "*"
        "Condition" = {
          "StringEqualsIfExists" = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "policy_for_ecs_task_service_role" {
  description = "IAM Policy for ECS Task Service}"
  policy      = data.aws_iam_policy_document.role_policy_ecs_task_role.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_excecution_role.name

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "role_policy_ecs_task_role" {
  statement {
    sid    = "AllowS3Actions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.codepipeline_bucket.arn}",
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }
  statement {
    sid    = "AllowIAMPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "AllowECRActions"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [aws_ecr_repository.repo.arn]
  }
  statement {
    sid    = "AllowECRAuthorization"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}
