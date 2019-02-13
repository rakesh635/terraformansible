provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}
resource "aws_instance" "jenkin" {
  ami           = "ami-0d773a3b7bb2bb1c1"
  instance_type = "t2.micro"
  key_name = "rakeshkey4"
  tags {
    Name = "jenkins-master"
  }
  provisioner "local-exec" {
    command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -e 'ansible_python_interpreter=/usr/bin/python3' --private-key ./deployer.pem -i '${aws_instance.jenkin.public_ip},' master.yml"
  }
}
