job "jenkins" {
  datacenters = ["dc1"]
  type        = "service"
  update {
    stagger = "15s"
    max_parallel = 1
  }

  group "jenkins" {
    count = 1

    task "jenkins" {
      driver = "docker"
      config {
        image = "jenkinsci/blueocean:latest"
        volumes = ["/vagrant/data/jenkins:/var/jenkins_home"]

        port_map {
          http = "8080"
          jnlp = "50000"
        }
      }

      resources {
        cpu    = 500
        memory = 768

        network {
          mbits = 10

          port "http" {
            static = 8080
          }
          port "jnlp" {
            static = 50000
          }
        }
      }

      service {
        name = "jenkins"
        tags = ["http"]
        port = "http"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
