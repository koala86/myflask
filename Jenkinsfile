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
          // 需要 Jenkins 构建节点安装 Docker CLI 并具备运行权限
          env.BUILT_IMAGE = "${params.IMAGE_NAME}:${params.IMAGE_TAG}"
          currentBuild.displayName = "${env.BUILD_NUMBER} ${env.BUILT_IMAGE}"
          sh label: 'Docker build', script: """
            set -euxo pipefail
            docker version
            docker build -t "${BUILT_IMAGE}" .
          """
        }
      }
    }

    stage('Smoke Test') {
      steps {
        script {
          def image = env.BUILT_IMAGE ?: "${params.IMAGE_NAME}:${params.IMAGE_TAG}"
          def cname = "myflask-${env.BUILD_ID}"
          try {
            sh label: 'Run container for smoke test', script: """
              set -euxo pipefail
              docker rm -f "${cname}" >/dev/null 2>&1 || true
              docker run -d --name "${cname}" -p 5000:5000 "${image}"
            """
            // 健康检查：等待应用启动并返回包含 Hello 的页面
            sh label: 'Health check', script: """
              set -euo pipefail
              for i in $(seq 1 30); do
                if command -v curl >/dev/null 2>&1; then
                  body=$(curl -fsS http://127.0.0.1:5000/ || true)
                else
                  body=$(wget -qO- http://127.0.0.1:5000/ || true)
                fi
                echo "$body" | grep -q 'Hello' && { echo 'Smoke test passed'; exit 0; }
                sleep 1
              done
              echo 'App did not become healthy in time' >&2
              exit 1
            """
          } finally {
            sh label: 'Cleanup container', script: """
              docker rm -f "${cname}" >/dev/null 2>&1 || true
            """
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
