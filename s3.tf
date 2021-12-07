resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "${var.name}-codepipeline"
  acl           = "private"
  force_destroy = true
}
