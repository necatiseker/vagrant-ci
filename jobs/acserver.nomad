job "acserver" {
  datacenters = ["dc1"]
  type        = "service"
  update {
    stagger = "15s"
    max_parallel = 1
  }

  group "acserver" {
    count = 1

    task "acserver" {
      driver = "exec"
      config {
        command = "/usr/bin/acserver"
        args    = ["/etc/acserver/config.yml"]
      }

    resources {
      cpu    = 250
      memory = 128

      network {
        mbits = 10

          port "http" {
            static = 3000
          }
        }
      }

      service {
        name = "acserver"
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
