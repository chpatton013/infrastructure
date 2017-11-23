# The runtime context needed when calculating hostvars for each machine.
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
    return @make_hostvars.call(
      @machine_factory,
      cluster,
      @machine_index,
      @num_machines,
    )
  end
end
