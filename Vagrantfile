class Machine
  attr_reader :name
  attr_reader :groups
  attr_reader :hostname
  attr_reader :static_ip
  attr_reader :hostvars

  def initialize(name:, groups:, hostname:, static_ip:, extra_hostvars:)
    @name = name
    @groups = groups
    @hostname = hostname
    @static_ip = static_ip

    default_hostvars = {
      hostname: @hostname,
      static_ip: @static_ip,
    }
    @hostvars = Hash[default_hostvars.merge(extra_hostvars).map() { |key, value|
      [key, value.to_json()]
    }]
  end

  def define(config)
    config.vm.define(@name) do |machine_config|
      machine_config.vm.network("private_network", ip: @static_ip)
      yield(machine_config)
    end
  end
end

class MachineFactory
  attr_reader :name
  attr_reader :groups
  attr_reader :hostname
  attr_reader :static_ip
  attr_reader :hostvars

  def initialize(name:, groups:, hostname:, static_ip:, hostvars: nil)
    @name = name
    @groups = groups
    @hostname = hostname
    @static_ip = static_ip
    @hostvars = if hostvars then hostvars else lambda { |*args| {} } end
  end

  def make(index, num_machines)
    return Machine.new(name: @name.(index),
                       groups: @groups.(index),
                       hostname: @hostname.(index),
                       static_ip: @static_ip.(index),
                       extra_hostvars: @hostvars.(self, index, num_machines))
  end

  def makeAll(num_machines)
    return (0..num_machines - 1).to_a().map() { |index|
      make(index, num_machines)
    }
  end
end

Vagrant.configure("2") do |config|
  kDomain = "example.com"
  kNumClient = 1
  kNumNtp = 2
  kNumDns = 1

  config.vm.box = "fedora/25-cloud-base"

  all_machines = [
    MachineFactory.new(
      groups: lambda { |index| ["client"] },
      name: lambda { |index| "client#{index}" },
      hostname: lambda { |index| "client#{index}.#{kDomain}" },
      static_ip: lambda { |index| "10.0.0.#{10 + index}" }).makeAll(kNumClient),
    MachineFactory.new(
      groups: lambda { |index| ["ntp"] },
      name: lambda { |index| "ntp#{index}" },
      hostname: lambda { |index| "#{index}.ntp.#{kDomain}" },
      static_ip: lambda { |index| "10.0.0.#{20 + index}" }).makeAll(kNumNtp),
    MachineFactory.new(
      groups: lambda { |index| ["dns"] },
      name: lambda { |index| "dns#{index}" },
      hostname: lambda { |index| "dns#{index}.#{kDomain}" },
      static_ip: lambda { |index| "10.0.0.#{30 + index}" }).makeAll(kNumDns),
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
