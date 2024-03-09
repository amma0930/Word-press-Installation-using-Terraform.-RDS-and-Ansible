provider "aws" {
  region     = "ap-south-1"
  access_key = "XXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXX"
}

# Create a new key pair for EC2 instance
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2-key"
  public_key = file("~/.ssh/ec2-key.pub") # Default public key path
}

# Create a security group allowing all inbound and outbound traffic
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group"
  description = "Allow all traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create EC2 instance with the new key pair
resource "aws_instance" "ec2_instance" {
  ami           = "ami-03bb6d83c60fc5f7c" # Replace with your desired AMI ID
  instance_type = "t2.micro"
  key_name      = "ec2-key"
  security_groups = ["ec2-security-group"]
  tags = {
    Name = "EC2Instance"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/ec2-key") # Default private key path
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y mysql-server",
      "sudo systemctl start mysql",
      "sudo systemctl enable mysql",
    ]
  }
}


# Create RDS instance
resource "aws_db_instance" "rds_instance" {
  identifier            = "my-rds-instance"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  username             = "admin"
  password             = "admin1234"
  publicly_accessible = false

  tags = {
    Name = "RDSInstance"
  }
}

# Output the RDS endpoint
output "rds_endpoint" {
  value = aws_db_instance.rds_instance.endpoint
}

# Output the EC2 public IP
output "ec2_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}
