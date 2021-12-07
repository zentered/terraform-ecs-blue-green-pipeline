resource "aws_kms_key" "keys" {
  description             = var.name
  deletion_window_in_days = 14
}
