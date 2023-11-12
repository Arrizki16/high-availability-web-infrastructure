# resource "random_id" "db_name_suffix" {
#   byte_length = 4
# }

resource "google_sql_database_instance" "sql_instance" {
  name             = "rpl-database"
  database_version = "MYSQL_8_0"
  region           = "asia-southeast1"

  settings {
    tier = "db-f1-micro"
    edition = "ENTERPRISE"
    disk_size = 10
    disk_type = "PD_SSD"
  }
}