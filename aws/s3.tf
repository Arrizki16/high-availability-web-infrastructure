resource "aws_s3_bucket" "rpl-s3-bucket" {
  bucket = "rpl-s3-bucket"
  depends_on = [ aws_db_instance.db-rpl ]
}