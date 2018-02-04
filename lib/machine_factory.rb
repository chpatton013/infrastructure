require_relative "hostvars_context"
require_relative "machine"

# A factory to produce any number of machines with the same configuration.
# Machine factories hold several lambdas, which are evaluated every time a
# machine is created.
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
    @hostvars = hostvars ? hostvars : ->(*_args) { {} }
  end

  def make(index, num_machines)
    hostvars_context = HostvarsContext.new(
      machine_factory: self,
      machine_index: index,
      num_machines: num_machines,
      make_hostvars: @hostvars,
    )

    return Machine.new(
      name: @name.call(index),
      groups: @groups.call(index),
      static_ip: @static_ip.call(index),
      hostname: @hostname.call(index),
      dns_record: @dns_record.call(index),
      hostvars_context: hostvars_context,
    )
  end

  def makeAll(num_machines)
    return (0..num_machines - 1).to_a().map() { |index|
      make(index, num_machines)
    }
  end
end
