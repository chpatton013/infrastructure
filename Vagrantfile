class Machine
  attr_reader :name
  attr_reader :groups
  attr_reader :hostname
  attr_reader :ip

  def initialize(name:, groups:, hostname:, ip:)
    @name = name
    @groups = groups
    @hostname = hostname
    @ip = ip
  end

  def hostvars()
    return {hostname: @hostname}
  end

  def define(config)
    config.vm.define(@name) do |machine_config|
      machine_config.vm.network("private_network", ip: @ip)
      yield(machine_config)
    end
  end
end

def makeMachines(num_machines:, groups:, make_name:, make_hostname:, make_ip:)
  return (0..num_machines - 1).to_a().map() { |index|
    Machine.new(name: make_name.(index),
                groups: groups,
                hostname: make_hostname.(index),
                ip: make_ip.(index))
  }
end

Vagrant.configure("2") do |config|
  kDomain = "example.com"
  kNumClient = 1
  kNumNtp = 2
  kNumDns = 1

  config.vm.box = "fedora/25-cloud-base"

  all_machines = [
    makeMachines(
      num_machines: kNumClient,
      groups: ["client"],
      make_name: lambda { |index| "client#{index}" },
      make_hostname: lambda { |index| "client#{index}.#{kDomain}" },
      make_ip: lambda { |index| "10.0.0.#{10 + index}" }),
    makeMachines(
      num_machines: kNumNtp,
      groups: ["ntp"],
      make_name: lambda { |index| "ntp#{index}" },
      make_hostname: lambda { |index| "#{index}.ntp.#{kDomain}" },
      make_ip: lambda { |index| "10.0.0.#{20 + index}" }),
    makeMachines(
      num_machines: kNumDns,
      groups: ["dns"],
      make_name: lambda { |index| "dns#{index}" },
      make_hostname: lambda { |index| "dns#{index}.#{kDomain}" },
      make_ip: lambda { |index| "10.0.0.#{30 + index}" }),
  ].reduce(:concat)

  # Invert the machine->[group] collection to group->[machine].
  machine_groups = all_machines.map() { |machine|
    Hash[machine.groups().map() { |group| [group, machine.name()] }]
  }.reduce({}) { |output, group_to_name|
    group_to_name.each() { |group, name| (output[group] ||= []) << name}
    output
  }

  machine_hostvars = Hash[all_machines.map() { |machine|
    [machine.name(), machine.hostvars()]
  }]

  all_machines.each_with_index() do |machine, index|
    machine.define(config) do |machine_config|
      machine_config.vm.provision("shell", path: "provision.sh")

      # Defer running ansible provisioning until the last machine to take
      # advantage of ansible's parallel executor.
      if index == all_machines.length - 1
        machine_config.vm.provision("ansible") do |ansible|
          ansible.verbose = true
          ansible.limit = "all"
          ansible.playbook = "provision.yml"
          ansible.host_vars = machine_hostvars
          ansible.groups = machine_groups
        end
      end
    end
  end
end
