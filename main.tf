/* 
Definir as configurações do projeto terraform
    - Definir Versões;
    - Definir Estados e etc; 
*/
/*
    Definir os providers necessários para o projeto
        - required_providers: Bloco para definir os providers necessários para o projeto
        - aws: Provider para AWS, onde vamos criar os recursos na AWS
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.39.0"
    }
  }
}

/*
    Configurar o provider AWS
        - region: Região onde os recursos serão criados
*/

provider "aws" {
  region = "us-east-1"
}

/*
    Criar uma VPC, qual recurso eu vou utilizar
        -aws_vpc: Recurso para criar uma VPC na AWS
        - vpc : Nome do recurso
        - aws_vpc
            - cidr_block: Bloco CIDR para a VPC
            - instance_tenancy: Define a tenência de instância para a VPC (default ou dedicated)
            - tags: Tags para identificar a VPC
*/

/* 
    10.0.0.0/16 é um bloco CIDR que representa um intervalo de endereços IP.
    10.0 é o endereço de rede, e /16 indica que os primeiros 16 bits do endereço IP são usados para identificar a rede, enquanto os últimos 16 bits são usados para identificar os hosts dentro dessa rede.
    0.0/16 é um bloco CIDR que representa um intervalo de endereços IP. Ou seja é o dispositivo que vai se conectar a VPC
*/
resource "aws_vpc" "vpc" {   // Criar uma VPC, qual recurso eu vou utilizar
  cidr_block = "10.0.0.0/16" //mascara de rede para a VPC

  tags = {
    Name = "main-vpc" // Tag para identificar a VPC
  }
}

/* 
    Criar uma Subnet, qual recurso eu vou utilizar
        -aws_subnet: Recurso para criar uma Subnet na AWS
        - main: Nome do recurso
        - aws_subnet
            - vpc_id: ID da VPC onde a Subnet será criada
            - cidr_block: Bloco CIDR para a Subnet
            - availability_zone: Zona de disponibilidade onde a Subnet será criada
            - tags: Tags para identificar a Subnet
*/
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private_subnet"
  }
}

/* 
    Criar um Internet Gateway, qual recurso eu vou utilizar
        -aws_internet_gateway: Recurso para criar um Internet Gateway na AWS
        - gw: Nome do recurso 
        - aws_internet_gateway
            - vpc_id: ID da VPC onde o Internet Gateway será criado
            - tags: Tags para identificar o Internet Gateway
*/
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet_gateway"
  }
}

/* 
    Criar um elastic IP, qual recurso eu vou utilizar
        -aws_eip: Recurso para criar um Elastic IP na AWS
        - nat_eip: Nome do recurso
        - aws_eip
            - tags: Tags para identificar o Elastic IP
*/
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "nat_eip"
  }
}

/* 
    Criar um NAT Gateway, qual recurso eu vou utilizar
        -aws_nat_gateway: Recurso para criar um NAT Gateway na AWS
        - nat_gateway: Nome do recurso
        - aws_nat_gateway
            - allocation_id: ID da alocação do Elastic IP para o NAT Gateway
            - subnet_id: ID da Subnet onde o NAT Gateway será criado

    Ip público para a Subnet privada acessar a internet, ou seja, o NAT Gateway é um 
    dispositivo que permite que instâncias em uma Subnet privada acessem a internet, 
    mas impede que a internet acesse essas instâncias diretamente. Ele atua como um 
    intermediário,roteando o tráfego de saída das instâncias privadas para a internet 
    e retornando as respostas para as instâncias privadas.
*/
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat_gateway"
  }
}


/* 
    Criar uma Route Table, qual recurso eu vou utilizar
        -aws_route_table: Recurso para criar uma Route Table na AWS
        - public_route_table: Nome do recurso
        - aws_route_table
            - vpc_id: ID da VPC onde a Route Table será criada
            - route: Bloco para definir as rotas na Route Table
                - cidr_block: Bloco CIDR para a rota
                - gateway_id: ID do gateway para a rota (pode ser um Internet Gateway ou um NAT Gateway)
            - tags: Tags para identificar a Route Table
*/
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private_route_table"
  }
}

/*
    Criar uma associação entre a Route Table e a Subnet, qual recurso eu vou utilizar
        -aws_route_table_association: Recurso para criar uma associação entre a Route Table e a Subnet na AWS
        - public_route_table_association: Nome do recurso
        - aws_route_table_association
            - subnet_id: ID da Subnet para associar à Route Table
            - route_table_id: ID da Route Table para associar à Subnet

    A associação entre a Route Table e a Subnet é necessária para que as rotas definidas na Route Table sejam aplicadas às instâncias na Subnet. Sem essa associação, as instâncias na Subnet não teriam acesso à internet ou a outros recursos fora da VPC, dependendo das rotas definidas na Route Table.
*/
resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


/* 
    Criar um Security Group, qual recurso eu vou utilizar
        -aws_security_group: Recurso para criar um Security Group na AWS
        - web_security_group_allow_tls: Nome do recurso
        - aws_security_group
            - description: Descrição do Security Group
            - vpc_id: ID da VPC onde o Security Group será criado
                - ingress: Bloco para definir as regras de entrada no Security Group
                    - from_port: Porta de origem para a regra de entrada
                    - to_port: Porta de destino para a regra de entrada
                    - protocol: Protocolo para a regra de entrada (tcp, udp, icmp, etc.)
                    - cidr_blocks: Blocos CIDR para a regra de entrada
                - egress: Bloco para definir as regras de saída no Security Group
                    - from_port: Porta de origem para a regra de saída
                    - to_port: Porta de destino para a regra de saída
                    - protocol: Protocolo para a regra de saída (tcp, udp, icmp, etc.)
                    - cidr_blocks: Blocos CIDR para a regra de saída
            - tags: Tags para identificar o Security Group
*/
resource "aws_security_group" "web_security_group_allow_tls" {
  description = "Security group for allowing TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  #SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //ip da sua rede que irá acessar a máquina, ou seja, o dispositivo que vai se conectar a VPC
  }

  #HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //ip da sua rede que irá acessar a máquina, ou seja, o dispositivo que vai se conectar a VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          // -1 significa todos os protocolos
    cidr_blocks = ["0.0.0.0/0"] //ip da sua rede que irá acessar a máquina, ou seja, o dispositivo que vai se conectar a VPC
  }

  tags = {
    Name = "web_security_group_allow_tls"
  }
}

resource "aws_security_group" "db_security_group_allow_tls" {
  description = "Security group for Database allowing TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  #SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block] //ip da sua rede que irá acessar a máquina, ou seja, o dispositivo que vai se conectar a VPC
  }

  #PostgreSQL
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_security_group_allow_tls.id] // Permitir acesso ao banco de dados apenas a partir do Security Group da aplicação web
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          // -1 significa todos os protocolos
    cidr_blocks = ["0.0.0.0/0"] //ip da sua rede que irá acessar a máquina, ou seja, o dispositivo que vai se conectar a VPC
  }

  tags = {
    Name = "db_security_group_allow_tls"
  }
}

/* 
    Criar um Key Pair, qual recurso eu vou utilizar
        -aws_key_pair: Recurso para criar um Key Pair na AWS
        - key: Nome do recurso
        - aws_key_pair
            - key_name: Nome do Key Pair
            - public_key: Chave pública para o Key Pair (pode ser lida a partir de um arquivo)
*/
resource "aws_key_pair" "key" {
  key_name   = "livesession-key"
  public_key = file("~/.ssh/id_rsa.pub") // Caminho para a sua chave pública
}

/*
    Criar uma instância EC2, qual recurso eu vou utilizar
        -aws_instance: Recurso para criar uma instância EC2 na AWS
        - web_instance: Nome do recurso para a instância web
        - db_instance: Nome do recurso para a instância de banco de dados
        - aws_instance
            - ami: ID da Amazon Machine Image (AMI) para a instância
            - instance_type: Tipo da instância (t2.micro, t3.micro, etc.)
            - subnet_id: ID da Subnet onde a instância será criada
            - vpc_security_group_ids: Lista de IDs dos Security Groups associados à instância
            - key_name: Nome do Key Pair para acessar a instância via SSH
            - associate_public_ip_address: Define se a instância deve ter um endereço IP público associado (true ou false)
            - tags: Tags para identificar a instância
*/
resource "aws_instance" "web_instance" {
  ami                         = "ami-0ec10929233384c7f" // Amazon Linux 2 AMI (HVM), SSD Volume Type, Canonical, Ubuntu, 24.04, amd64 noble image
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_security_group_allow_tls.id]
  key_name                    = aws_key_pair.key.key_name
  associate_public_ip_address = true

  tags = {
    Name = "ec2_web_instance"
  }
}

resource "aws_instance" "db_instance" {
  ami                    = "ami-0ec10929233384c7f" // Amazon Linux 2 AMI (HVM), SSD Volume Type, Canonical, Ubuntu, 24.04, amd64 noble image
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.db_security_group_allow_tls.id]
  key_name               = aws_key_pair.key.key_name

  tags = {
    Name = "ec2_db_instance"
  }
}
