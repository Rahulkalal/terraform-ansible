provider "aws" {
  region = "us-west-2"  # Change to your desired region
}

# Create a security group that allows inbound traffic on port 80 (HTTP)
resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Provision an EC2 instance
resource "aws_instance" "web_server" {
  ami           = "ami-12345678"  # Replace with a valid AMI ID
  instance_type = "t2.micro"
  key_name      = "my-key-pair"   # Replace with your key pair
  security_groups = [aws_security_group.web_sg.name]

  # Install Ansible and run a playbook using the remote-exec provisioner
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y ansible",
      "echo '[webservers]' > /tmp/hosts",
      "echo '${self.public_ip} ansible_connection=ssh ansible_user=ubuntu' >> /tmp/hosts",
      "ansible-playbook -i /tmp/hosts /tmp/nginx-playbook.yml"
    ]

    connection {
      type     = "ssh"
      user     = "ubuntu"  # Adjust based on the AMI's default user
      private_key = file("~/.ssh/my-key-pair.pem")  # Path to your private key
      host     = self.public_ip
    }
  }
}

# Output the instance's public IP
output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}
