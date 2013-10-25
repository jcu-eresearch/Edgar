# -*- mode: ruby -*-
# vi: set ft=ruby :

# Use vagrant version 2
Vagrant.configure("2") do |config|

  ##########################
  #    UNIVERSAL CONFIG    #
  ##########################

  # All machines will use a common CentOS-6 (64 bit) base
  config.vm.box     = "centos-64-x64-vbox4210"
  # Use the box provided by puppetlabs (this is just CentOS-6 with puppet pre-installed)
  config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/centos-64-x64-vbox4210.box"

  config.vm.synced_folder "salt/roots/", "/srv/"


  ##########################
  #   COMPUTE VM CONFIG    #
  ##########################
  config.vm.define :compute do |compute|
      compute.vm.network :private_network, ip: "192.168.100.100"
      compute.vm.hostname = "compute"

      # Overide default virtualbox config options
      compute.vm.provider :virtualbox do |vb|
        # Give the VM 1GB of memory
        vb.customize ["modifyvm", :id, "--memory", "1024"]
      end


      compute.vm.provision :salt do |salt|
        salt.minion_config = "salt/compute_minion"
        salt.run_highstate = true
        salt.verbose = true

        salt.install_type = 'git'
        salt.install_args = 'v0.17.1'
      end
  end


  ##########################
  # Applications VM CONFIG  #
  ##########################
  config.vm.define :applications do |applications|
      applications.vm.network :private_network, ip: "192.168.100.101"
      applications.vm.hostname = "applications"

      applications.vm.provision :salt do |salt|
        salt.minion_config = "salt/applications_minion"
        salt.run_highstate = true
        salt.verbose = true

        salt.install_type = 'git'
        salt.install_args = 'v0.17.1'
      end
  end


  ##########################
  #  Map Server VM CONFIG  #
  ##########################
  config.vm.define :map_server do |map_server|
      map_server.vm.network :private_network, ip: "192.168.100.102"
      map_server.vm.hostname = "map-server"

      map_server.vm.provision :salt do |salt|
        salt.minion_config = "salt/map_server_minion"
        salt.run_highstate = true
        salt.verbose = true

        salt.install_type = 'git'
        salt.install_args = 'v0.17.1'
      end
  end

end
