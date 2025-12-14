pipeline {
  agent any

  options {
    timeout(time: 20, unit: 'MINUTES')
  }

  parameters {
    string(name: 'IMAGE_NAME', defaultValue: 'myflask', description: 'Docker 镜像名称')
    string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Docker 镜像标签')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker image') {
      steps {
        script {
          // 需要 Jenkins 节点已安装 Docker
          def img = docker.build("${params.IMAGE_NAME}:${params.IMAGE_TAG}")
          // 将镜像对象保存到当前运行时以供后续阶段使用
          currentBuild.displayName = "${env.BUILD_NUMBER} ${params.IMAGE_NAME}:${params.IMAGE_TAG}"
          env.BUILT_IMAGE = "${params.IMAGE_NAME}:${params.IMAGE_TAG}"
        }
      }
    }

    stage('Smoke Test') {
      steps {
        script {
          def img = docker.image(env.BUILT_IMAGE ?: "${params.IMAGE_NAME}:${params.IMAGE_TAG}")
          img.withRun('-p 5000:5000') { c ->
            // 简单的健康检查：等待应用启动并返回包含 Hello 的页面
            sh '''
            set -e
            for i in $(seq 1 30); do
              if wget -qO- http://127.0.0.1:5000/ | grep -q 'Hello'; then
                echo "Smoke test passed"
                exit 0
              fi
              sleep 1
            done
            echo "App did not become healthy in time" >&2
            exit 1
            '''
          }
        }
      }
    }

    // 如需推送镜像，可在此添加 withRegistry(...) 并 docker.push()
  }

  post {
    always {
      archiveArtifacts artifacts: 'Dockerfile,main.py', fingerprint: true, onlyIfSuccessful: false
    }
  }
}
