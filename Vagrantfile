Vagrant.configure("2") do |config|

  # Servidor de base de datos
  config.vm.define "dbGodino" do |db|
    db.vm.box = "debian/bullseye64"
    db.vm.network "private_network", ip: "192.168.57.14", virtualbox__intnet: "prnetwork_db"
    db.vm.provision "shell", path: "db.sh"
  end

  # Servidor NFS
  config.vm.define "NFSGodino" do |nfs|
    nfs.vm.box = "debian/bullseye64"
    nfs.vm.network "private_network", ip: "192.168.56.13", virtualbox__intnet: "prnetwork"
    nfs.vm.network "private_network", ip: "192.168.57.13", virtualbox__intnet: "prnetwork_db"
    nfs.vm.provision "shell", path: "nfs.sh"
  end

  # Servidores web
  config.vm.define "web1Godino" do |serverweb1|
    serverweb1.vm.box = "debian/bullseye64"
    serverweb1.vm.network "private_network", ip: "192.168.56.11", virtualbox__intnet: "prnetwork"
    serverweb1.vm.network "private_network", ip: "192.168.57.11", virtualbox__intnet: "prnetwork_db"
    serverweb1.vm.provision "shell", path: "web.sh"
  end

  config.vm.define "web2Godino" do |serverweb2|
    serverweb2.vm.box = "debian/bullseye64"
    serverweb2.vm.network "private_network", ip: "192.168.56.12", virtualbox__intnet: "prnetwork"
    serverweb2.vm.network "private_network", ip: "192.168.57.12", virtualbox__intnet: "prnetwork_db"
    serverweb2.vm.provision "shell", path: "web.sh"
  end

  # Máquina balanceador
  config.vm.define "balanceadorGodino" do |balanceador|
    balanceador.vm.box = "debian/bullseye64"
    balanceador.vm.network "public_network"
    balanceador.vm.network "forwarded_port", guest: 80, host: 8080
    balanceador.vm.network "private_network", ip: "192.168.56.10", virtualbox__intnet: "prnetwork"
    balanceador.vm.provision "shell", path: "balanceador.sh"
  end

end
