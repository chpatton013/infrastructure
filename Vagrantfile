class DnsDomain
  attr_reader :name
  attr_reader :metadata
  attr_reader :records

  def initialize(name:, metadata:, records:)
    @name = name
    @metadata = metadata
    @records = records
  end

  def type()
    return "NATIVE"
  end

  def toHash()
    return {
      name: @name,
      metadata: @metadata.map() { |metadata| metadata.toHash() },
      records: @records.map() { |records| records.toHash() },
    }
  end
end

class DnsDomainMetadata
  attr_reader :kind
  attr_reader :content

  def initialize(kind:, content:)
    @kind = kind
    @content = content
  end

  def toHash()
    return {
      kind: @kind,
      content: @content,
    }
  end
end

class DnsRecord
  attr_reader :name
  attr_reader :type
  attr_reader :content
  attr_reader :ttl

  def initialize(name:, type:, content:, ttl:)
    @name = name
    @type = type
    @content = content
    @ttl = ttl
  end

  def prio()
    return nil
  end

  def disabled()
    return 0
  end

  def ordername()
    return @name
  end

  def auth()
    return 1
  end

  def toHash()
    return {
      name: @name,
      type: @type,
      content: @content,
      ttl: @ttl,
      prio: prio(),
      disabled: disabled(),
      ordername: ordername(),
      auth: auth(),
    }
  end
end

def makeSoaRecord(cluster, ttl: 86400)
  return DnsRecord.new(name: cluster.nameservers()[0].dns_record(),
                       type: "SOA",
                       content: cluster.hostmasters()[0].dns_record(),
                       ttl: ttl)
end

def makeARecord(machine, ttl: 120)
  return DnsRecord.new(name: machine.dns_record(),
                       type: "A",
                       content: machine.static_ip(),
                       ttl: ttl)
end

def makeARecordGroup(name, machines, ttl: 120)
  return DnsRecord.new(name: name,
                       type: "A",
                       content: machines.map() { |machine|
                         machine.static_ip()
                       }.join(","),
                       ttl: ttl)
end

class HostvarsContext
  attr_reader :machine_factory
  attr_reader :machine_index
  attr_reader :num_machines

  def initialize(machine_factory:,
                 machine_index:,
                 num_machines:,
                 make_hostvars:)
    @machine_factory = machine_factory
    @machine_index = machine_index
    @num_machines = num_machines
    @make_hostvars = make_hostvars
  end

  def make(cluster)
    return @make_hostvars.(@machine_factory,
                           cluster,
                           @machine_index,
                           @num_machines)
  end
end

class Machine
  attr_reader :name
  attr_reader :groups
  attr_reader :static_ip
  attr_reader :hostname
  attr_reader :dns_record
  attr_reader :hostvars_context

  def initialize(name:,
                 groups:,
                 static_ip:,
                 hostname:,
                 dns_record:,
                 hostvars_context:)
    @name = name
    @groups = groups
    @static_ip = static_ip
    @hostname = hostname
    @dns_record = dns_record
    @hostvars_context = hostvars_context
  end

  def define(config)
    config.vm.define(@name) do |machine_config|
      machine_config.vm.network("private_network", ip: @static_ip)
      yield(machine_config)
    end
  end

  def hostvars(cluster)
    default_hostvars = {
      machine_static_ip: @machine_static_ip,
      machine_hostname: @hostname,
      machine_dns_record: @dns_record,
    }
    extra_hostvars = @hostvars_context.make(cluster)

    return Hash[default_hostvars.merge(extra_hostvars).map() { |key, value|
      [key, value.to_json()]
    }]
  end
end

class MachineFactory
  attr_reader :name
  attr_reader :groups
  attr_reader :static_ip
  attr_reader :hostname
  attr_reader :dns_record
  attr_reader :hostvars

  def initialize(name:,
                 groups:,
                 static_ip:,
                 hostname:,
                 dns_record:,
                 hostvars: nil)
    @name = name
    @groups = groups
    @static_ip = static_ip
    @hostname = hostname
    @dns_record = dns_record
    @hostvars = if hostvars then hostvars else lambda { |*args| {} } end
  end

  def make(index, num_machines)
    hostvars_context = HostvarsContext.new(machine_factory: self,
                                           machine_index: index,
                                           num_machines: num_machines,
                                           make_hostvars: @hostvars)

    return Machine.new(
      name: @name.(index),
      groups: @groups.(index),
      static_ip: @static_ip.(index),
      hostname: @hostname.(index),
      dns_record: @dns_record.(index),
      hostvars_context: hostvars_context)
  end

  def makeAll(num_machines)
    return (0..num_machines - 1).to_a().map() { |index|
      make(index, num_machines)
    }
  end
end

class Cluster
  attr_reader :name
  attr_reader :subnet_cidr
  attr_reader :machines

  def initialize(name:, subnet_cidr:, machines:)
    @name = name
    @subnet_cidr = subnet_cidr
    @machines = machines
  end

  def define(config)
    @machines.each() { |machine|
      machine.define(config) { |machine_config| yield(machine_config, self) }
    }
  end

  # Invert the machine->[group] collection to group->[machine].
  def machinesByGroup()
    return @machines.map() { |machine|
      Hash[machine.groups().map() { |group| [group, machine.name()] }]
    }.reduce({}) { |output, group_to_name|
      group_to_name.each() { |group, name| (output[group] ||= []) << name}
      output
    }
  end

  def hostvarsByMachineName()
    return Hash[@machines.map() { |machine|
      [machine.name(), machine.hostvars(self)]
    }]
  end

  def machinesWithName(name)
    return @machines.select() { |machine| machine.groups().include?(name) }
  end

  def hostmasters()
    return machinesWithName("hostmaster")
  end

  def dnsBackends()
    return machinesWithName("dns_backend")
  end

  def nameservers()
    return machinesWithName("auth_dns")
  end

  def timeservers()
    return machinesWithName("ntp")
  end

  def dnsDomain(domain_name)
    soa = makeSoaRecord(self)

    # Use DNS to load balance acros all NTP servers.
    ntp = makeARecordGroup("ntp.#{domain_name}", timeservers())

    machine_records = @machines.map() { |machine| makeARecord(machine) }

    return DnsDomain.new(
      name: domain_name,
      metadata: [],
      records: [soa, ntp] + machine_records,
    )
  end
end

Vagrant.configure("2") do |config|
  kDomain = "example.com"
  kNumNtp = 2
  kNumHostmaster = 1
  kNumDnsBackend = 1
  kNumAuthoratativeDns = 2
  kNumRecursiveDns = 2

  config.vm.box = "fedora/25-cloud-base"

  dns_backend_db_user_password = "password";

  all_machines = [
    MachineFactory.new(
      groups: lambda { |index| ["ntp"] },
      name: lambda { |index| "ntp#{index}" },
      static_ip: lambda { |index| "10.0.0.#{20 + index}" },
      hostname: lambda { |index| "ntp#{index}" },
      dns_record: lambda { |index| "#{index}.ntp.#{kDomain}" },
    ).makeAll(kNumNtp),
    MachineFactory.new(
      groups: lambda { |index| ["hostmaster"] },
      name: lambda { |index| "hostmaster#{index}" },
      static_ip: lambda { |index| "10.0.0.#{30 + index}" },
      hostname: lambda { |index| "hostmaster#{index}" },
      dns_record: lambda { |index| "hostmaster#{index}.#{kDomain}" },
      hostvars: lambda { |factory, cluster, machine_index, num_machines|
        hostmasters = cluster.hostmasters()
        dns_backends = cluster.dnsBackends()
        nameservers = cluster.nameservers()
        {
          ssl_key_name: "default",
          ssl_country_name: "US",
          ssl_state_or_province_name: "CA",
          ssl_organization_name: "O",
          ssl_organizational_unit_name: "OU",
          ssl_common_name: "CN",
          ssl_email_address: "chpatton013@gmail.com",
          hostmaster_host: hostmasters[0].dns_record(),
          dns_backend_host: dns_backends[0].static_ip(),
          dns_backend_db_user_password: dns_backend_db_user_password,
          primary_ns_host: nameservers[0].dns_record(),
          secondary_ns_host: nameservers[1].dns_record(),
          poweradmin_session_key: "supersecret",
        }
      },
    ).makeAll(kNumHostmaster),
    MachineFactory.new(
      groups: lambda { |index| ["dns_backend"] },
      name: lambda { |index| "dns_backend#{index}" },
      static_ip: lambda { |index| "10.0.0.#{40 + index}" },
      hostname: lambda { |index| "dns_backend#{index}" },
      dns_record: lambda { |index| "dns_backend#{index}.#{kDomain}" },
      hostvars: lambda { |factory, cluster, machine_index, num_machines|
        domains = [cluster.dnsDomain(kDomain)]
        {
          mysql_db_root_password: "password",
          dns_backend_db_user_password: dns_backend_db_user_password,
          dns_backend_domains: domains.map() { |domain| domain.toHash() },
        }
      },
    ).makeAll(kNumDnsBackend),
    MachineFactory.new(
      groups: lambda { |index| ["auth_dns"] },
      name: lambda { |index| "auth_dns#{index}" },
      static_ip: lambda { |index| "10.0.0.#{50 + index}" },
      hostname: lambda { |index| "auth_dns#{index}" },
      dns_record: lambda { |index| "ns#{index + 1}.#{kDomain}" },
      hostvars: lambda { |factory, cluster, machine_index, num_machines|
        dns_backends = cluster.dnsBackends()
        {
          dns_backend_host: dns_backends[0].static_ip(),
          dns_backend_db_user_password: dns_backend_db_user_password,
        }
      },
    ).makeAll(kNumAuthoratativeDns),
  ].reduce(:concat)

  cluster = Cluster.new(name: "primary_cluster",
                        subnet_cidr: "10.0.0.0/8",
                        machines: all_machines)

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
          ansible.host_vars = cluster.hostvarsByMachineName()
          ansible.groups = cluster.machinesByGroup()
        end
      end
    end
  end
end
