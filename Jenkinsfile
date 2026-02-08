pipeline {
  agent any

  parameters {
    choice(
      name: 'ENV',
      choices: ['staging', 'production'],
      description: 'Terraform environment to validate'
    )
  }

  environment {
    TF_IN_AUTOMATION = "true"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Format') {
      steps {
        sh 'terraform fmt -check -recursive'
      }
    }

    stage('Terraform Init') {
      steps {
        dir("environments/${params.ENV}") {
          sh 'terraform init -backend=false'
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        dir("environments/${params.ENV}") {
          sh 'terraform validate'
        }
      }
    }

    stage('TFLint') {
      steps {
        sh '''
        tflint --init
        tflint
        '''
      }
    }

    stage('Checkov Security Scan') {
      steps {
        sh '''
        checkov -d . \
          --framework terraform \
          --quiet
        '''
      }
    }

    stage('Terraform Plan (dry-run)') {
      steps {
        dir("environments/${params.ENV}") {
          sh '''
          terraform plan \
            -input=false \
            -lock=false \
            -no-color
          '''
        }
      }
    }
  }

  post {
    success {
      echo "✅ CI passed for ${params.ENV}. Safe to apply manually."
    }
    failure {
      echo "❌ CI failed for ${params.ENV}. Fix before apply."
    }
  }
}
