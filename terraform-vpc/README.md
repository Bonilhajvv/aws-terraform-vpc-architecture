# AWS Infrastructure with Terraform

Este projeto utiliza o **Terraform** para provisionar uma infraestrutura completa e segura na AWS, incluindo VPC, Subnets Públicas e Privadas, NAT Gateway e instâncias EC2.

---

## Arquitetura do Projeto

A infraestrutura segue as melhores práticas de rede na nuvem:

- **VPC (Virtual Private Cloud)**: Rede virtual isolada na nuvem.
- **Subnets**: Subdivisão lógica da rede em segmentos menores.
  - **Pública**: Para recursos que precisam de acesso direto à internet (ex: Web Server).
  - **Privada**: Para recursos que devem permanecer protegidos (ex: Banco de Dados).
- **Internet Gateway**: Ponto de entrada e saída para a internet global.
- **NAT Gateway**: Permite que instâncias em subnets privadas acessem a internet (para atualizações, por exemplo) sem que a internet as acesse diretamente.

---

## Pré-requisitos

Antes de começar, você precisará instalar e configurar as seguintes ferramentas:

### AWS CLI

#### Instalação
- **Ubuntu / Debian (recomendado):**
  ```bash
  sudo apt update
  sudo apt install -y awscli
  ```
- **Linux (Manual - Versão mais atual):**
  ```bash
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  ```
- **Arch / BigLinux:**
  ```bash
  sudo pacman -S aws-cli
  ```

**Verificar instalação:** `aws --version`

#### Configurar credenciais AWS
Execute o comando abaixo e preencha com suas chaves:
```bash
aws configure
```
*Preencha com sua `Access Key ID`, `Secret Access Key`, região `us-east-1` e formato `json`.*

#### Testar configuração
`aws s3 ls`
- Se listar seus buckets (ou não retornar erro de permissão), está funcionando! ✅

> [!WARNING]
> **Permissões:** O usuário IAM utilizado deve ter permissões suficientes. Para fins de estudo, a política `AdministratorAccess` pode ser usada (com cautela).

---

### Terraform

#### Instalação
- **Ubuntu / Debian:**
  ```bash
  sudo apt update
  sudo apt install -y terraform
  ```
- **Arch / BigLinux:**
  ```bash
  sudo pacman -S terraform
  ```

**Verificar instalação:** `terraform -v`

---

## Como Utilizar


Siga os passos abaixo na ordem para gerenciar sua infraestrutura:

### 1. Inicializar o ambiente
`terraform init`
- Instala os providers necessários (AWS).
- Cria o diretório de estado local `.terraform/`.

### 2. Padronizar o código
`terraform fmt`
- Aplica a formatação padrão da HashiCorp em todos os arquivos `.tf`.

### 3. Validar a configuração
`terraform validate`
- Verifica erros de sintaxe e lógica antes da execução.

### 4. Planejar as mudanças
`terraform plan`
- Mostra um relatório detalhado do que será criado, modificado ou destruído.

### 5. Aplicar a infraestrutura
`terraform apply`
- Provisiona os recursos reais na sua conta AWS.

---

## Conceitos Fundamentais

### Região vs Zona de Disponibilidade
- **Região**: Área geográfica onde a AWS possui datacenters (ex: `us-east-1`).
- **Zona de Disponibilidade (AZ)**: Datacenters isolados dentro de uma região para garantir alta disponibilidade.

![Regiões da AWS](images/region.png)
![Zonas de Disponibilidade](images/availability_zone.png)

### Por que usar Terraform?
1. **Infraestrutura como Código (IaC)**: Declare sua infraestrutura de forma legível.
2. **Automação**: Elimina processos manuais e erros humanos.
3. **Escalabilidade**: Reutilize módulos para criar ambientes idênticos rapidamente.
4. **Gerenciamento de Estado**: O Terraform mantém o controle do que já foi criado.

### Providers e Registry
Os **Providers** são plugins que permitem ao Terraform se comunicar com diferentes nuvens (AWS, Azure, GCP). Você pode encontrar todos no [Terraform Registry](https://registry.terraform.io/).

---

## Créditos e Agradecimentos

Este projeto foi desenvolvido com base no conteúdo e ensinamentos de **Fabricio Veronez**.

<!-- - **Vídeo de referência**: https://www.youtube.com/watch?v=cQlS0QpGYSk -->


ssh ubuntu@(IP publico da subrede publica)