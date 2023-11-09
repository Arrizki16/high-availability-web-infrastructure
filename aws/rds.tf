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
    publicly_accessible = false
    vpc_security_group_ids = ["${aws_security_group.rds_sg.id}"]
    skip_final_snapshot = true

}

resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  vpc_id = aws_vpc.rpl-vpc.id
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
    subnet_ids = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id, aws_subnet.subnet-3.id]
}

# resource "null_resource" "setup-db" {
#   depends_on = [ aws_db_instance.db-rpl ]
#   provisioner "local-exec" {
#     command = "mysql -u ${aws_db_instance.db-rpl.username} -p${var.RDS_PASS} -h ${aws_db_instance.db-rpl.address} < db.sql"
#   }
# }