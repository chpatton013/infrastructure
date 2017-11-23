# DNS records provide a collection of address mappings with a DNS domain.
# Records can be of varying types which can map:
# * subdomains to subdomains
# * subdomains to IP addresses
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
