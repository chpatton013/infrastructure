require_relative "lib/cluster"
require_relative "lib/dns_domain"
require_relative "lib/dns_domain_metadata"
require_relative "lib/dns_record"
require_relative "lib/hostvars_context"
require_relative "lib/machine"
require_relative "lib/machine_factory"

def makeNtpMachines(num_machines, domain:)
  return MachineFactory.new(
    groups: ->(_index) { ["ntp"] },
    name: ->(index) { "ntp#{index}" },
    static_ip: ->(index) { "10.0.0.#{20 + index}" },
    hostname: ->(index) { "ntp#{index}" },
    dns_record: ->(index) { "#{index}.ntp.#{domain}" },
  ).makeAll(num_machines)
end

def makeHostmasterMachines(num_machines,
                           domain:,
                           dns_backend_db_user_password:)
  return MachineFactory.new(
    groups: ->(_index) { ["hostmaster"] },
    name: ->(index) { "hostmaster#{index}" },
    static_ip: ->(index) { "10.0.0.#{30 + index}" },
    hostname: ->(index) { "hostmaster#{index}" },
    dns_record: ->(index) { "hostmaster#{index}.#{domain}" },
    hostvars: lambda { |_factory, cluster, _machine_index, _num_machines|
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
  ).makeAll(num_machines)
end

def makeDnsBackendMachines(num_machines,
                           domain:,
                           dns_backend_db_user_password:)
  return MachineFactory.new(
    groups: ->(_index) { ["dns_backend"] },
    name: ->(index) { "dns_backend#{index}" },
    static_ip: ->(index) { "10.0.0.#{40 + index}" },
    hostname: ->(index) { "dns_backend#{index}" },
    dns_record: ->(index) { "dns_backend#{index}.#{domain}" },
    hostvars: lambda { |_factory, cluster, _machine_index, _num_machines|
      domains = [cluster.dnsDomain(domain)]
      {
        mysql_db_root_password: "password",
        dns_backend_db_user_password: dns_backend_db_user_password,
        dns_backend_domains: domains.map(&:toHash),
      }
    },
  ).makeAll(num_machines)
end

def makeAuthoratativeDnsMachines(num_machines,
                                 domain:,
                                 dns_backend_db_user_password:)
  return MachineFactory.new(
    groups: ->(_index) { ["auth_dns"] },
    name: ->(index) { "auth_dns#{index}" },
    static_ip: ->(index) { "10.0.0.#{50 + index}" },
    hostname: ->(index) { "auth_dns#{index}" },
    dns_record: ->(index) { "auth_dns#{index}.#{domain}" },
    hostvars: lambda { |_factory, cluster, _machine_index, _num_machines|
      dns_backends = cluster.dnsBackends()
      {
        dns_backend_host: dns_backends[0].static_ip(),
        dns_backend_db_user_password: dns_backend_db_user_password,
      }
    },
  ).makeAll(num_machines)
end

def makeAllMachines(num_ntp:,
                    num_hostmaster:,
                    num_dns_backend:,
                    num_authoratative_dns:,
                    domain:,
                    dns_backend_db_user_password:)
  [
    makeNtpMachines(num_ntp, domain: domain),
    makeHostmasterMachines(
      num_hostmaster,
      domain: domain,
      dns_backend_db_user_password: dns_backend_db_user_password,
    ),
    makeDnsBackendMachines(
      num_dns_backend,
      domain: domain,
      dns_backend_db_user_password: dns_backend_db_user_password,
    ),
    makeAuthoratativeDnsMachines(
      num_authoratative_dns,
      domain: domain,
      dns_backend_db_user_password: dns_backend_db_user_password,
    ),
  ].reduce(:concat)
end

def defineMachines(config:, machines:, cluster:)
  machines.each_with_index() do |machine, index|
    machine.define(config) do |machine_config|
      machine_config.vm.provision("shell", path: "provision.sh")

      # Defer running ansible provisioning until the last machine to take
      # advantage of ansible's parallel executor.
      if index == machines.length - 1
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

Vagrant.configure("2") do |config|
  kDomain = "example.com"
  kNumNtp = 2
  kNumHostmaster = 1
  kNumDnsBackend = 1
  kNumAuthoratativeDns = 2
  kDnsBackendDbUserPassword = "password"

  config.vm.box = "fedora/25-cloud-base"

  all_machines = makeAllMachines(
    num_ntp: kNumNtp,
    num_hostmaster: kNumHostmaster,
    num_dns_backend: kNumDnsBackend,
    num_authoratative_dns: kNumAuthoratativeDns,
    domain: kDomain,
    dns_backend_db_user_password: kDnsBackendDbUserPassword,
  )

  cluster = Cluster.new(name: "primary_cluster",
                        subnet_cidr: "10.0.0.0/8",
                        machines: all_machines)

  defineMachines(config: config, machines: all_machines, cluster: cluster)
end
