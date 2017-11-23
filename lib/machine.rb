# A single machine in a cluster. A machine represents all of the information
# needed to define a VM for Vagrant.
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

  def _defaultHostvars()
    return {
      machine_static_ip: @static_ip,
      machine_hostname: @hostname,
      machine_dns_record: @dns_record,
    }
  end

  def hostvars(cluster)
    default_hostvars = _defaultHostvars()
    extra_hostvars = @hostvars_context.make(cluster)

    return Hash[default_hostvars.merge(extra_hostvars).map() { |key, value|
      value_json = value.to_json()

      # Double-encode complex hostvars so we can correctly decode them later.
      if value.is_a?(Array) || value.is_a?(Hash)
        value_json = value_json.to_json()
      end

      [key, value_json]
    }]
  end
end
