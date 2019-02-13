
Use Terraform and Ansible to provision an ec2 instance and launch jenkins service.

# Ansible with Terraform :

In devops world, we frequently come across terraform and ansible. But will be confused where to use these and how to use it combined. Here we can learn how to combine these two to configure the ec2 instance, created by terraform. 

# Ansible vs Terraform :

In general term we can mention this difference as configuration management vs orchestration. Terraform is for provisioning your infrastructure and Ansible is for configuring the infrastructure. Both can do other’s task a bit, but they are in market to do their primary task.

This is a document, where we use them to do their primary task and combine them to launch a jenkins service.

# Launch Jenkins in EC2 :

## Prerequisite :

Terraform installed (used Terraform v0.11.10)
Ansible installed (used ansible 2.7.7), both in same machine.

## Files :

First we should have to provision an infrastructure for jenkins. Here we use terraform for that. We a need to start with a terraform file.
```
jenkins.tf :

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
```

I have use aws provider to launch an ubuntu instance. For accessing the variables (accesskey, secretkey), create variable.tf and terraform.tfvars files. As mentioned, used linux image and mentioned its flavour, key, tagname. I already have a key, rakeshkey4. If you want them to create them in fly, you can use  ‘ resource "aws_key_pair" ‘. Also be ready with pem file for your key.

Provisioners are used to execute scripts on a local or remote machine as part of resource creation or destruction. Provisioners can be used to bootstrap a resource, cleanup before destroy, run configuration management, etc. I used to execute local script for configuration management.

So your terraform folder should contain, <somename>.tf, variable.tf, terraform.tfvars and pem file. Along with this, we need to have a ansible playbook to configure jenkins (master.yml).
```
master.yml :

- hosts: all
  become: true

  tasks:
    - name: Add the webupd8 APT repository
      apt_repository: repo="ppa:webupd8team/java" state=present

    - name: Automatically select the Oracle License
      shell: echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
      changed_when: false

    - name: Install Oracle Java
      apt: name={{item}} state=present force=yes
      with_items:
      - oracle-java8-installer

    - name: Set JAVA_HOME
      shell: sudo echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.bashrc

    - name: ensure the jenkins apt repository key is installed
      apt_key: url=https://pkg.jenkins.io/debian-stable/jenkins.io.key state=present

    - name: ensure the repository is configured
      apt_repository: repo='deb https://pkg.jenkins.io/debian-stable binary/' state=present

    - name: ensure jenkins is installed
      apt: name=jenkins update_cache=yes

    - name: ensure jenkins is running
      service: name=jenkins state=started
```
This is very much straight forward approach to launch jenkins in ubuntu 16.04. 

## Steps :

Once your files are ready, start with terraform init statement. 
Next you can apply them using terraform apply

Once applied, first terraform creates a ubuntu flavoured ec2 instance. Then used provisioner, executes the ansible playbook to launch jenkins service in that.
