resource "aws_ecs_cluster" "cluster" {
  name = var.name

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.keys.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.logs.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "api"
  memory                   = 512
  cpu                      = 256
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_excecution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_service_role.arn

  container_definitions = jsonencode([
    {
      name      = var.name,
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true
      logConfiguration = {
        logDriver     = "awslogs",
        secretOptions = null
        options = {
          awslogs-region        = var.region
          awslogs-group         = var.name
          awslogs-stream-prefix = "ecs"
        }
      },
      portMappings = [
        {
          "containerPort" = 8080,
          "hostPort"      = 8080
        }
      ],
      environment = [
        { "name" = "DATABASE_HOST", "value" = var.database_host },
        { "name" = "DATABASE_NAME", "value" = var.database_name },
        { "name" = "DATABASE_USER", "value" = var.database_user },
        { "name" = "DATABASE_PASSWORD", "value" = var.database_pass }
      ]
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = var.name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.api.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  depends_on      = [aws_lb_listener.green, aws_lb_listener.blue]

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green.arn
    container_name   = var.name
    container_port   = 8080
  }

  network_configuration {
    subnets = [aws_subnet.private_subnets[0].id, aws_subnet.private_subnets[1].id]
    security_groups = [
      aws_security_group.sg.id
    ]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      load_balancer,
      desired_count,
      task_definition
    ]
  }
}
