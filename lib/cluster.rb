# Factory for DnsRecord with parameters for the Start-of-Authority record.
def makeSoaRecord(cluster, ttl: 86400)
  return DnsRecord.new(name: cluster.nameservers()[0].dns_record(),
                       type: "SOA",
                       content: cluster.hostmasters()[0].dns_record(),
                       ttl: ttl)
end

# Factory for DnsRecord with parameters for single-IP A-records.
def makeARecord(machine, ttl: 120)
  return DnsRecord.new(name: machine.dns_record(),
                       type: "A",
                       content: machine.static_ip(),
                       ttl: ttl)
end

# Factory for DnsRecord with parameters for multi-IP A-records.
def makeARecordGroup(name, machines, ttl: 120)
  return DnsRecord.new(name: name,
                       type: "A",
                       content: machines.map(&:static_ip).join(","),
                       ttl: ttl)
end

# A cluster holds a set of machines, provides accessors for named machine
# groups, and provides factories for data that is derived from collections of
# machines.
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
    # Create machine hash.
    machines_by_group = @machines.map() { |machine|
      Hash[machine.groups().map() { |group| [group, machine.name()] }]
    }

    # Insert machines into each group list.
    machines_by_group.each_with_object({}) do |group_to_name, output|
      group_to_name.each() do |group, name|
        (output[group] ||= []) << name
      end
    end

    return machines_by_group
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
