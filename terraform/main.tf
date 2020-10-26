
# Demo App

# Demo App Logging Bucket
#
# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
#
resource "aws_s3_bucket" "logs" {

  bucket = format("%s-logs", var.name)

  acl = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = var.tags
}

data "template_file" "bucket_policy" {

  template = file("bucket_policy_logging.json")

  vars = {

    elb_account_id = "156460612806" # AWS ELB account id for eu-west-1 see doc link above

    bucket_name = aws_s3_bucket.logs.bucket
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {

  bucket = aws_s3_bucket.logs.bucket

  policy = data.template_file.bucket_policy.rendered
}