resource "aws_db_instance" "db-rpl" {
    db_name = "rpl"
    allocated_storage = 20
    identifier = "db-rpl"
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "8.0.33"
    instance_class = "db.t3.micro"
    username = var.RDS_USER
    password = var.RDS_PASS
    db_subnet_group_name = "${aws_db_subnet_group.db-subnet.name}"
    publicly_accessible = true
    vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]
    skip_final_snapshot = true

}

resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "db-subnet" {
    name = "db-subnet"
    subnet_ids = ["subnet-09c24fde4eb965cb4", "subnet-06a261c9dbd53f4a3", "subnet-0715e175e8ca284d0"]
}

resource "null_resource" "setup-db" {
  depends_on = [ aws_db_instance.db-rpl ]
  provisioner "local-exec" {
    command = "mysql -u ${aws_db_instance.db-rpl.username} -p${var.RDS_PASS} -h ${aws_db_instance.db-rpl.address} < db.sql"
  }
}