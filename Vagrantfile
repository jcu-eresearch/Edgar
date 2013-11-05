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
      compute.vm.network :private_network, ip: "192.168.100.110"
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
      applications.vm.network :private_network, ip: "192.168.100.111"
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
      map_server.vm.network :private_network, ip: "192.168.100.112"
      map_server.vm.hostname = "map-server"

      map_server.vm.provision :salt do |salt|
        salt.minion_config = "salt/map_server_minion"
        salt.run_highstate = true
        salt.verbose = true

        salt.install_type = 'git'
        salt.install_args = 'v0.17.1'
      end
  end

  ############################
  # NECTAR COMPUTE VM CONFIG #
  ############################
  config.vm.define :nectar_compute do |nectar_compute|

    # The box isn't used (hence it's just a dummy box)
    nectar_compute.vm.box     = "dummy"
    nectar_compute.vm.box_url = "https://github.com/cloudbau/vagrant-openstack-plugin/raw/master/dummy.box"

    nectar_compute.ssh.private_key_path = "~/.ssh/id_rsa"

    nectar_compute.vm.provider :openstack do |os|
      # Change these...
      os.username     = "#{ENV['NECTAR_USERNAME']}"
      os.api_key      = "#{ENV['NECTAR_API_KEY']}"
      os.keypair_name = "#{ENV['NECTAR_KEYPAIR']}"
      os.tenant       = "#{ENV['NECTAR_CLIMAS_COMPUTE_TENANT']}"

      os.flavor       = /m1.xxlarge/
      os.image        = "e84371d5-cda5-4e53-9851-08a4150b13a7"
      os.endpoint     = "https://keystone.rc.nectar.org.au:5000/v2.0/tokens"
      os.ssh_username = "ec2-user"

      os.security_groups   = ['ssh', 'rsync']
      os.availability_zone = "qld"
    end

    nectar_compute.vm.provision :salt do |salt|
      salt.minion_config = "salt/compute_minion"
      salt.run_highstate = true
      salt.verbose = true

      salt.install_type = 'git'
      salt.install_args = 'v0.17.1'
    end
  end

  #################################
  # NECTAR APPLICATIONS VM CONFIG #
  #################################
  config.vm.define :nectar_applications do |nectar_applications|

    # The box isn't used (hence it's just a dummy box)
    nectar_applications.vm.box     = "dummy"
    nectar_applications.vm.box_url = "https://github.com/cloudbau/vagrant-openstack-plugin/raw/master/dummy.box"

    nectar_applications.ssh.private_key_path = "~/.ssh/id_rsa"

    nectar_applications.vm.provider :openstack do |os|
      # Change these...
      os.username     = "#{ENV['NECTAR_USERNAME']}"
      os.api_key      = "#{ENV['NECTAR_API_KEY']}"
      os.keypair_name = "#{ENV['NECTAR_KEYPAIR']}"
      os.tenant       = "#{ENV['NECTAR_CLIMAS_APPLICATIONS_TENANT']}"

      os.flavor       = /m1.medium/
      os.image        = "e84371d5-cda5-4e53-9851-08a4150b13a7"
      os.endpoint     = "https://keystone.rc.nectar.org.au:5000/v2.0/tokens"
      os.ssh_username = "ec2-user"

      os.security_groups   = ['ssh', 'web', 'rsync']
      os.availability_zone = "qld"
    end

    nectar_applications.vm.provision :salt do |salt|
      salt.minion_config = "salt/applications_minion"
      salt.run_highstate = true
      salt.verbose = true

      salt.install_type = 'git'
      salt.install_args = 'v0.17.1'
    end
  end

  ###############################
  # NECTAR MAP SERVER VM CONFIG #
  ###############################
  config.vm.define :nectar_map_server do |nectar_map_server|

    # The box isn't used (hence it's just a dummy box)
    nectar_map_server.vm.box     = "dummy"
    nectar_map_server.vm.box_url = "https://github.com/cloudbau/vagrant-openstack-plugin/raw/master/dummy.box"

    nectar_map_server.ssh.private_key_path = "~/.ssh/id_rsa"

    nectar_map_server.vm.provider :openstack do |os|
      # Change these...
      os.username     = "#{ENV['NECTAR_USERNAME']}"
      os.api_key      = "#{ENV['NECTAR_API_KEY']}"
      os.keypair_name = "#{ENV['NECTAR_KEYPAIR']}"
      os.tenant       = "#{ENV['NECTAR_CLIMAS_MAP_SERVER_TENANT']}"

      os.flavor       = /m1.medium/
      os.image        = "e84371d5-cda5-4e53-9851-08a4150b13a7"
      os.endpoint     = "https://keystone.rc.nectar.org.au:5000/v2.0/tokens"
      os.ssh_username = "ec2-user"

      os.security_groups   = ['ssh', 'web', 'postgres', 'rsync']
      os.availability_zone = "qld"
    end

    nectar_map_server.vm.provision :salt do |salt|
      salt.minion_config = "salt/map_server_minion"
      salt.run_highstate = true
      salt.verbose = true

      salt.install_type = 'git'
      salt.install_args = 'v0.17.1'
    end
  end

end
