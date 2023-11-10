resource "aws_iam_policy" "s3-policy" {
  name = "S3-Bucket-Access-Policy"
  path = "/"
  description = "Provides permission to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:DeleteObject"
            ],
            Effect = "Allow",
            Resource = [
                "arn:aws:s3:::*/*",
                "${aws_s3_bucket.rpl-s3-bucket.arn}"
                # "arn:aws:s3:::rpl-s3-bucket-for-final-project-research-rpl-2023"
            ]
        }
    ]
  })
}

resource "aws_iam_role" "webuser-role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole",
            Effect = "Allow",
            Sid = "RoleForEC2",
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }
    ]
  })
}

resource "aws_iam_policy_attachment" "policy-attach" {
  name = "policy-attach"
  roles = [aws_iam_role.webuser-role.name]
  policy_arn = aws_iam_policy.s3-policy.arn
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-profile"
  role = aws_iam_role.webuser-role.name
}