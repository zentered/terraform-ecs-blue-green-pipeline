
resource "aws_codebuild_project" "build" {
  name           = var.name
  build_timeout  = 5
  queued_timeout = 30
  badge_enabled  = false

  service_role = aws_iam_role.codebuild_service_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/standard:5.0"
    compute_type                = "BUILD_GENERAL1_SMALL"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.repo.repository_url
    }

    environment_variable {
      name  = "TASK_DEFINITION"
      value = aws_ecs_task_definition.api.arn
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = var.name
    }
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.name
      stream_name = var.name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "api/buildspec.yml"
  }
}
