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
          def hostPort = "5001" // avoid common conflicts on shared agents
          try {
            sh label: 'Run container for smoke test', script: """
              set -euxo pipefail
              docker rm -f "${cname}" >/dev/null 2>&1 || true
              # Bind container port 5000 to 127.0.0.1:${hostPort} on the host to avoid exposure and reduce conflicts
              docker run -d --name "${cname}" -p 127.0.0.1:${hostPort}:5000 "${image}"
              # Capture inspect info for diagnostics
              docker inspect "${cname}" > "inspect-${cname}.json" || true
              # Store variables for use in single-quoted shell blocks
              echo "${cname}" > .cname
              echo "${hostPort}" > .hostport
              # Capture container IP (bridge network) if any; empty if using host/none
              docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${cname}" > .cip || true
            """
            // 健康检查：等待应用启动并返回包含 Hello 的页面
            // 注意：使用 Groovy 三引号单引号，避免 $ 被 Groovy 解析
            sh label: 'Health check', script: '''
              set -euo pipefail
              cname=$(cat .cname)
              host_port=$(cat .hostport)
              container_ip=$(cat .cip || true)
              for i in $(seq 1 60); do
                # fail fast if container already exited
                if ! docker ps --filter "name=${cname}" --filter "status=running" -q >/dev/null 2>&1; then
                  echo "Container ${cname} is not running" >&2
                  docker logs "${cname}" || true
                  docker logs "${cname}" > "container-${cname}.log" 2>&1 || true
                  exit 1
                fi
                if command -v curl >/dev/null 2>&1; then
                  body=$(curl -fsS "http://127.0.0.1:${host_port}/" || true)
                else
                  body=$(wget -qO- "http://127.0.0.1:${host_port}/" || true)
                fi
                echo "$body" | grep -q 'Hello' && { echo 'Smoke test passed'; exit 0; }
                # Fallback: try container IP if localhost mapping is not reachable (e.g., remote Docker)
                if [ -n "$container_ip" ]; then
                  if command -v curl >/dev/null 2>&1; then
                    body=$(curl -fsS "http://${container_ip}:5000/" || true)
                  else
                    body=$(wget -qO- "http://${container_ip}:5000/" || true)
                  fi
                  echo "$body" | grep -q 'Hello' && { echo 'Smoke test passed (via container IP)'; exit 0; }
                fi
                sleep 1
              done
              echo 'App did not become healthy in time' >&2
              # dump logs for diagnostics
              docker logs "${cname}" || true
              docker logs "${cname}" > "container-${cname}.log" 2>&1 || true
              exit 1
            '''
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
      archiveArtifacts artifacts: 'Dockerfile,main.py,inspect-*.json,container-*.log', fingerprint: true, onlyIfSuccessful: false
    }
  }
}
