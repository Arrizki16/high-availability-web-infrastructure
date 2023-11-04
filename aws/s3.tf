resource "aws_s3_bucket" "rpl-s3-bucket" {
  bucket = "rpl-s3-bucket-for-final-project-research-rpl-2023"
  force_destroy = true
  depends_on = [ aws_db_instance.db-rpl ]
}