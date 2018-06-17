Vagrant.configure("2") do |config|

  config.vm.define "ci" do |ci|
    ci.vm.box = "debian/contrib-stretch64"
    ci.vm.network "private_network", ip: "192.168.10.10"
    ci.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end
    ci.vm.synced_folder ".", "/vagrant"
    ci.vm.provision :shell, :privileged => true, :path => "scripts/priv-base.sh"
    ci.vm.provision :shell, :privileged => true, :path => "scripts/priv-consul.sh"
    ci.vm.provision :shell, :privileged => true, :path => "scripts/priv-vault.sh"
    ci.vm.provision :shell, :privileged => true, :path => "scripts/priv-nomad.sh"
    ci.vm.provision "docker"
    # ci.vm.provision :shell, :privileged => true, :path => "scripts/priv-rkt.sh"
    # ci.vm.provision :shell, :inline => "usermod -a -G rkt-admin vagrant"
    # ci.vm.provision :shell, :inline => "usermod -a -G rkt vagrant"
    # ci.vm.provision :shell, :privileged => true, :path => "scripts/priv-dgr.sh"
    # ci.vm.provision :shell, :privileged => true, :path => "scripts/priv-acserver.sh"
  end
end
