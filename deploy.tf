###########################
##### APP PACKAGING ########
###########################
# Zips webapp/ (app.py, templates, static, requirements.txt) and uploads it to S3.
# EC2 instances pull this at boot instead of baking the app into a custom AMI.

data "archive_file" "webapp_package" {
  type        = "zip"
  source_dir  = "${path.module}/webapp"
  output_path = "${path.module}/.build/webapp.zip"
  excludes    = ["__pycache__/app.cpython-313.pyc"]
}

resource "aws_s3_object" "webapp_package" {
  bucket = aws_s3_bucket.secure_bucket.id
  key    = "artifacts/webapp.zip"
  source = data.archive_file.webapp_package.output_path
  etag   = data.archive_file.webapp_package.output_md5 # forces re-upload whenever webapp/ changes
}
