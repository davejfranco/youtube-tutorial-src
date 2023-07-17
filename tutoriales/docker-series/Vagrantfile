# -*- mode: ruby -*-
# vi: set ft=ruby :
# vagrant plugin install vagrant-scp to allow scp to guest
# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "generic/ubuntu2004"
  config.vm.provider "virtualbox" do |v|
    v.cpus = 2
    v.memory = 1512
    #v.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
  end
  config.vm.network "forwarded_port", guest: 80, host: 8080
end