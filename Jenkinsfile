pipeline {
  agent { label 'linux' }
  options {
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  stages {
        stage('SCM Checkout') {
            steps{
                git branch: 'master', url: 'https://github.com/almw/WebApplicationDemoSecurityScan.git'
            }
        }
        // Execute SonarQube code quality scan
        stage('Run Sonarqube') {
            environment {
                scannerHome = tool 'WebApplicationDemoSecurityScan-sonar-tool';
            }
            steps {
              withSonarQubeEnv(credentialsId: 'WebApplicationDemoSecurityScan-sonar-credentials', installationName: 'WebApplicationDemoSecurityScan sonar installation') {
                sh "${scannerHome}/bin/sonar-scanner"
              }
            }
        }
        // Build Docker Container
        stage('Build') {
          steps {
            sh 'docker build -t azurecontainerregistryxxxx101/webapplicationdemosecurityscan:latest .'
          }
        }
        // Execute Aqua Trivy Vulnerability and Misconfiguration Scanning
        stage('Scan') {
          steps {
            sh 'trivy --no-progress --severity MEDIUM,HIGH,CRITICAL azurecontainerregistryxxxx101/webapplicationdemosecurityscan:latest'
          }
        }
        stage('deploy') {
              def resourceGroup = '<resource_group>'
              def webAppName = '<app_name>'
              // login Azure
              withCredentials([usernamePassword(credentialsId: '<service_princial>', passwordVariable: 'AZURE_CLIENT_SECRET', usernameVariable: 'AZURE_CLIENT_ID')]) {
              sh '''
                  az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
                  az account set -s $AZURE_SUBSCRIPTION_ID
                '''
              }
              // get publish settings
              def pubProfilesJson = sh script: "az webapp deployment list-publishing-profiles -g $resourceGroup -n $webAppName", returnStdout: true
              def ftpProfile = getFtpPublishProfile pubProfilesJson
              // upload package
              sh "curl -T target/calculator-1.0.war $ftpProfile.url/webapps/ROOT.war -u '$ftpProfile.username:$ftpProfile.password'"
              // log out
              sh 'az logout'
            }
      }
}