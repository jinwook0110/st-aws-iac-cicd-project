# st-aws-iac-cicd-project
AWS Infrastructure as Code with CloudFormation and Terraform

# AWS IaC CI/CD Project

このリポジトリは、AWS CloudFormationとTerraformを使用したInfrastructure as Code (IaC)および、GitHub Actionsを使用したCI/CDパイプラインの実装例です。

## プロジェクト構成

- `infrastructure/cloudformation/`: CloudFormationテンプレート
- `infrastructure/terraform/`: Terraformスクリプト
- `lambda_functions/`: Lambda関数のソースコード
  - `text_to_s3/`: S3バケットにテキストファイルを保存するLambda関数
  - `numbers_1_to_1000/`: 1〜1000の数字を生成するLambda関数
  - `numbers_1001_to_2000/`: 1001〜2000の数字を生成するLambda関数
- `.github/workflows/`: GitHub Actionsワークフロー定義

## デプロイ方法

### 必要条件
- AWS CLIがインストールされていること
- AWS認証情報が設定されていること

### 手動デプロイ手順

#### 1. Lambda関数のパッケージング

```bash
cd lambda_functions/text_to_s3/
zip -r ../text_to_s3.zip *
cd ../numbers_1_to_1000/
zip -r ../numbers_1_to_1000.zip *
cd ../numbers_1001_to_2000/
zip -r ../numbers_1001_to_2000.zip *
cd ../../
