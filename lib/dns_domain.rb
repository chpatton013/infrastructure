# A DNS domain binds metadata and records to a partial domain name.
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
      type: type(),
      metadata: @metadata.map(&:toHash),
      records: @records.map(&:toHash),
    }
  end
end
