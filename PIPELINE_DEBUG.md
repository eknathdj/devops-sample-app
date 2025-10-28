# 🔍 Pipeline Debug Guide

## Issue: Pipeline Completes Immediately

The pipeline is completing in seconds without running any stages, which indicates one of these issues:

### **Possible Causes:**

1. **Jenkins can't find the Jenkinsfile.devsecops**
2. **Pipeline syntax error causing silent failure**
3. **Agent not available**
4. **SCM checkout failing silently**

### **Debug Steps:**

#### **Step 1: Check Pipeline Configuration**

1. **Go to your pipeline** in Jenkins
2. **Click "Configure"**
3. **Verify these settings**:
   - **Pipeline Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/eknathdj/devops-sample-app`
   - **Credentials**: `github-creds` (should be selected)
   - **Branch Specifier**: `*/main`
   - **Script Path**: `Jenkinsfile.devsecops`

#### **Step 2: Test with Direct Pipeline Script**

1. **Change Pipeline Definition** to "Pipeline script"
2. **Copy this test script**:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Test') {
            steps {
                script {
                    echo '🧪 Testing pipeline execution...'
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Workspace: ${WORKSPACE}"
                    
                    sh '''
                        echo "Current directory:"
                        pwd
                        echo "Files in directory:"
                        ls -la
                        echo "Git status:"
                        git status || echo "Not a git repository"
                        echo "✅ Test completed"
                    '''
                }
            }
        }
    }
}
```

3. **Save and Build**

#### **Step 3: Check Console Output Carefully**

Look for these specific messages in the console output:

- **"Obtained Jenkinsfile.devsecops from git"** - Should appear if SCM works
- **"Started by user"** - Should show who triggered the build
- **Any error messages** about file not found or syntax errors

#### **Step 4: Verify Git Credentials**

1. **Go to**: Manage Jenkins → Credentials
2. **Check that `github-creds` exists and is valid**
3. **Test the credentials**:
   - Create a simple pipeline with just `checkout scm`
   - See if it can access the repository

#### **Step 5: Check Jenkins System Log**

1. **Go to**: Manage Jenkins → System Log
2. **Look for any errors** related to pipeline execution
3. **Check for SCM-related errors**

### **Quick Fix Options:**

#### **Option 1: Use Pipeline Script Directly**

Instead of SCM, paste the entire Jenkinsfile.devsecops content directly into the pipeline configuration.

#### **Option 2: Test with Minimal Pipeline**

Use this minimal pipeline to test:

```groovy
pipeline {
    agent any
    stages {
        stage('Hello') {
            steps {
                echo 'Hello World - Pipeline is working!'
                sh 'echo "Shell commands work too"'
            }
        }
    }
}
```

#### **Option 3: Check File Path**

Make sure `Jenkinsfile.devsecops` exists in the root of your repository and is committed to the main branch.

### **Expected Behavior:**

When working correctly, you should see:

```
Started by user DevSecOps Admin
Obtained Jenkinsfile.devsecops from git https://github.com/eknathdj/devops-sample-app
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/devsecops-sample-app
[Pipeline] {
[Pipeline] stage
[Pipeline] { (🔧 Setup & Checkout)
[Pipeline] script
[Pipeline] {
[Pipeline] echo
🔧 Setting up environment and checking out code...
...
```

If you're not seeing this detailed output, there's definitely a configuration issue.