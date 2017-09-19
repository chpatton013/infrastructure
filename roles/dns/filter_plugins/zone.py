import ansible
import math

try:
    import netaddr
except Exception, e:
    raise ansible.errors.AnsibleFilterError("python-netaddr package missing")

def _subnet_blocks(cidr):
    network = netaddr.IPNetwork(cidr)
    ip = network.ip
    prefix = network.prefixlen

    if network.ip != network.network:
        raise ansible.errors.AnsibleFilterError(
                "Invalid CIDR: IP {ip} is within prefix {prefix}".format(
                    ip=ip, prefix=prefix))

    # Filter out the masked address blocks.
    return ip.words[:int(math.ceil(prefix / 8))]

def zone(cidr):
    return ".".join(map(str, _subnet_blocks(cidr)))

def reverse_zone(cidr):
    return ".".join(map(str, reversed(_subnet_blocks(cidr))))

class FilterModule(object):
    def filters(self):
        return {
            "zone": zone,
            "reverse_zone": reverse_zone,
        }
