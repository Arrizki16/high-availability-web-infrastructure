resource "google_storage_bucket" "cloud-storage-new" {
  name     = "rpl-cs"
  location = "ASIA"
  force_destroy = true
}

resource "google_storage_bucket_access_control" "public_reader_rule" {
  bucket = google_storage_bucket.cloud-storage-new.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_access_control" "public_writer_rule" {
  bucket = google_storage_bucket.cloud-storage-new.name
  role   = "WRITER"
  entity = "allUsers"
}