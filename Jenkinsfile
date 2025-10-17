pipeline {
    agent any
    
    environment {
        // CHANGE THIS TO YOUR DOCKER HUB USERNAME
        DOCKER_REGISTRY = 'eknathdj' 
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/sample-app:${BUILD_NUMBER}"
        GIT_REPO = 'https://github.com/eknathdj/devops-sample-app.git'
        // REMOVE OR CHANGE THIS LINE
        // GIT_CREDENTIALS_ID = 'git-creds' 
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: env.GIT_REPO, credentialsId: env.GIT_CREDENTIALS_ID
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build(env.DOCKER_IMAGE)
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${env.DOCKER_REGISTRY}", 'docker-registry-creds') {
                        docker.image(env.DOCKER_IMAGE).push()
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    // Update the image tag in the deployment
                    sh "sed -i 's|image: .*|image: ${env.DOCKER_IMAGE}|' environments/staging/deployment.yaml"
                    
                    // Commit and push changes
                    withCredentials([usernamePassword(credentialsId: env.GIT_CREDENTIALS_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh """
                            git config --global user.name "Jenkins"
                            git config --global user.email "jenkins@example.com"
                            git add environments/staging/deployment.yaml
                            git commit -m "Update image to ${env.DOCKER_IMAGE}"
                            git push https://${GIT_USER}:${GIT_PASS}@${env.GIT_REPO.replace('https://', '')} HEAD:main
                        """
                    }
                }
            }
        }
    }
}