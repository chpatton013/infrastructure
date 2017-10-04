{% if dns_backend_domains %}
  INSERT INTO `domains` (`name`, `type`)
  VALUES
  {% for domain in dns_backend_domains | from_json %}
    ('{{ domain["name"] }}', '{{ domain["type"] }}')
    {% if loop.last %};{% else %},{% endif %}
  {% endfor %}
{% endif %}

{% for domain in dns_backend_domains | from_json %}
  {% set domain_id = loop.index %}

  {% if domain["metadata"] %}
    INSERT INTO `domainmetadata` (`domain_id`, `kind`, `content`)
    VALUES
    {% for metadata in domain["metadata"] %}
      ({{ domain_id }}, '{{ metadata["kind"] }}', '{{ metadata["content"] }}')
      {% if loop.last %};{% else %},{% endif %}
    {% endfor %}
  {% endif %}

  {% if domain["records"] %}
    INSERT INTO `records` (`domain_id`,
                           `name`,
                           `type`,
                           `content`,
                           `ttl`,
                           `prio`,
                           `disabled`,
                           `ordername`,
                           `auth`)
    VALUES
    {% for record in domain["records"] %}
      ({{ domain_id }},
       '{{ record["name"] }}',
       '{{ record["type"] }}',
       '{{ record["content"] }}',
       {{ record["ttl"] }},
       {{ record["prio"] if record["prio"] is not none else "NULL" }},
       {{ record["disabled"] }},
       '{{ record["ordername"] }}',
       {{ record["auth"] }})
      {% if loop.last %};{% else %},{% endif %}
    {% endfor %}
  {% endif %}
{% endfor %}
