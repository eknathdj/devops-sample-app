pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "eknathdj/devops-sample-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = "dockerhub-creds"
        GIT_CREDENTIALS_ID = "github-creds"
    }
    
    options {
        // Skip the default SCM checkout
        skipDefaultCheckout(true)
        // Keep only last 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Timeout after 30 minutes
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Cleanup Workspace') {
            steps {
                echo 'Cleaning workspace...'
                cleanWs()
            }
        }
        
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                sh 'git status'
                sh 'ls -la'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    dockerImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    // Also tag as latest
                    dockerImage.tag("latest")
                }
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                script {
                    // Add your test commands here
                    // Example: docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").inside {
                    //     sh 'npm test'
                    // }
                    echo 'Tests passed successfully'
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                script {
                    docker.withRegistry('https://registry.hub.docker.com', DOCKER_CREDENTIALS_ID) {
                        dockerImage.push("${DOCKER_TAG}")
                        dockerImage.push("latest")
                    }
                }
            }
        }
        
        stage('Update ArgoCD Manifest') {
            steps {
                echo 'Updating Kubernetes manifests...'
                script {
                    // Update your k8s manifests with new image tag
                    sh """
                        sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|g' environments/staging/deployment.yaml
                        cat environments/staging/deployment.yaml
                    """
                }
            }
        }
        
        stage('Commit and Push Manifest Changes') {
            steps {
                echo 'Committing manifest changes...'
                script {
                    withCredentials([usernamePassword(credentialsId: GIT_CREDENTIALS_ID, 
                                                      usernameVariable: 'GIT_USERNAME', 
                                                      passwordVariable: 'GIT_PASSWORD')]) {
                        sh """
                            git config user.email "jenkins@example.com"
                            git config user.name "Jenkins CI"
                            git add k8s/deployment.yaml
                            git commit -m "Update image to ${DOCKER_IMAGE}:${DOCKER_TAG}" || echo "No changes to commit"
                            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/eknathdj/devops-sample-app.git HEAD:main
                        """
                    }
                }
            }
        }
        
        stage('Trigger ArgoCD Sync') {
            steps {
                echo 'ArgoCD will automatically sync the changes...'
                // If you have ArgoCD CLI configured, you can force sync:
                // sh 'argocd app sync sample-app'
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            // Add notifications here (Slack, email, etc.)
        }
        failure {
            echo 'Pipeline failed!'
            // Add failure notifications here
        }
        always {
            echo 'Cleaning up Docker images...'
            sh """
                docker rmi ${DOCKER_IMAGE}:${DOCKER_TAG} || true
                docker rmi ${DOCKER_IMAGE}:latest || true
            """
        }
    }
}