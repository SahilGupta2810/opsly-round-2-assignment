terraform {
  backend "s3" {
    bucket       = "opsly-tf-state-demo"
    key          = "opsly-infra"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
