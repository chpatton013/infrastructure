class Config
  DOMAIN = "example.com".freeze()
  TTL_A_RECORD = 120
  TTL_SOA = 86400

  class DnsBackend
    DB_USER_PASSWORD = "password".freeze()
  end

  class Mysql
    DB_ROOT_PASSWORD = "password".freeze()
  end

  class Poweradmin
    SESSION_KEY = "supersecret".freeze()
  end

  class Ssl
    COMMON_NAME = "CN".freeze()
    COUNTRY_NAME = "US".freeze()
    EMAIL_ADDRESS = "chpatton013@gmail.com".freeze()
    KEY_NAME = "default".freeze()
    ORGANIZATIONAL_UNIT_NAME = "OU".freeze()
    ORGANIZATION_NAME = "O".freeze()
    STATE_OR_PROVINCE_NAME = "CA".freeze()
  end
end
