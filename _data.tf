data aws_caller_identity "my_account_num" {}

data "http" "my_ip" {
  url = "https://ifconfig.co"
}

data aws_iam_policy_document "instance_assume_role_policy"{
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type = "Service"
    }
  }
}

