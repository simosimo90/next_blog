terraform {

    backend "s3" {

    bucket = "nextjs-blog-state"
    key = "next-js-blog/prod/terraform.tfstate"
    region = "eu-central-1"
    use_lockfile = true
    } 

}