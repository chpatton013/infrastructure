require_relative "lib/config"
require_relative "lib/cluster"
require_relative "lib/machine_factory"

def makeNtpMachines(num_machines)
  return MachineFactory.new(
    groups: ->(_index) { ["ntp"] },
    name: ->(index) { "ntp#{index}" },
    static_ip: ->(index) { "10.0.0.#{20 + index}" },
    hostname: ->(index) { "ntp#{index}" },
    dns_record: ->(index) { "#{index}.ntp.#{Config::DOMAIN}" },
  ).makeAll(num_machines)
end

def makeHostmasterMachines(num_machines)
  return MachineFactory.new(
    groups: ->(_index) { ["hostmaster"] },
    name: ->(index) { "hostmaster#{index}" },
    static_ip: ->(index) { "10.0.0.#{30 + index}" },
    hostname: ->(index) { "hostmaster#{index}" },
    dns_record: ->(index) { "hostmaster#{index}.#{Config::DOMAIN}" },
    hostvars: lambda { |_factory, cluster, _machine_index, _num_machines|
      hostmasters = cluster.hostmasters()
      dns_backends = cluster.dnsBackends()
      nameservers = cluster.nameservers()
      {
        ssl_key_name: Config::Ssl::KEY_NAME,
        ssl_country_name: Config::Ssl::COUNTRY_NAME,
        ssl_state_or_province_name: Config::Ssl::STATE_OR_PROVINCE_NAME,
        ssl_organization_name: Config::Ssl::ORGANIZATION_NAME,
        ssl_organizational_unit_name: Config::Ssl::ORGANIZATIONAL_UNIT_NAME,
        ssl_common_name: Config::Ssl::COMMON_NAME,
        ssl_email_address: Config::Ssl::EMAIL_ADDRESS,
        hostmaster_host: hostmasters[0].dns_record(),
        dns_backend_host: dns_backends[0].static_ip(),
        dns_backend_db_user_password: Config::DnsBackend::DB_USER_PASSWORD,
        primary_ns_host: nameservers[0].dns_record(),
        secondary_ns_host: nameservers[1].dns_record(),
        poweradmin_session_key: Config::Poweradmin::SESSION_KEY,
      }
    },
  ).makeAll(num_machines)
end

def makeDnsBackendMachines(num_machines)
  return MachineFactory.new(
    groups: ->(_index) { ["dns_backend"] },
    name: ->(index) { "dns_backend#{index}" },
    static_ip: ->(index) { "10.0.0.#{40 + index}" },
    hostname: ->(index) { "dns_backend#{index}" },
    dns_record: ->(index) { "dns_backend#{index}.#{Config::DOMAIN}" },
    hostvars: lambda { |_factory, cluster, _machine_index, _num_machines|
      domains = [cluster.dnsDomain(Config::DOMAIN)]
      {
        mysql_db_root_password: Config::Mysql::DB_ROOT_PASSWORD,
        dns_backend_db_user_password: Config::DnsBackend::DB_USER_PASSWORD,
        dns_backend_domains: domains.map(&:toHash),
      }
    },
  ).makeAll(num_machines)
end

def makeAuthoratativeDnsMachines(num_machines)
  return MachineFactory.new(
    groups: ->(_index) { ["auth_dns"] },
    name: ->(index) { "auth_dns#{index}" },
    static_ip: ->(index) { "10.0.0.#{50 + index}" },
    hostname: ->(index) { "auth_dns#{index}" },
    dns_record: ->(index) { "auth_dns#{index}.#{Config::DOMAIN}" },
    hostvars: lambda { |_factory, cluster, _machine_index, _num_machines|
      dns_backends = cluster.dnsBackends()
      {
        dns_backend_host: dns_backends[0].static_ip(),
        dns_backend_db_user_password: Config::DnsBackend::DB_USER_PASSWORD,
      }
    },
  ).makeAll(num_machines)
end

def makeAllMachines(num_ntp:,
                    num_hostmaster:,
                    num_dns_backend:,
                    num_authoratative_dns:)
  [
    makeNtpMachines(num_ntp),
    makeHostmasterMachines(num_hostmaster),
    makeDnsBackendMachines(num_dns_backend),
    makeAuthoratativeDnsMachines(num_authoratative_dns),
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
  kNumNtp = 2
  kNumHostmaster = 1
  kNumDnsBackend = 1
  kNumAuthoratativeDns = 2

  config.vm.box = "fedora/25-cloud-base"

  all_machines = makeAllMachines(
    num_ntp: kNumNtp,
    num_hostmaster: kNumHostmaster,
    num_dns_backend: kNumDnsBackend,
    num_authoratative_dns: kNumAuthoratativeDns,
  )

  cluster = Cluster.new(name: "primary_cluster",
                        subnet_cidr: "10.0.0.0/8",
                        machines: all_machines)

  defineMachines(config: config, machines: all_machines, cluster: cluster)
end
