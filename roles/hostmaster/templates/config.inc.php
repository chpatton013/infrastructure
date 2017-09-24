<?php

// Database settings
$db_host = "{{dns_backend_host}}";
$db_user = "{{dns_backend_db_user_name}}";
$db_pass = "{{dns_backend_db_user_password}}";
$db_name = "{{dns_backend_db_name}}";
$db_type = "mysql";
$db_charset = "utf8";

// Interface settings
$iface_lang = "en_EN";
$timezone = "UTC";

// DNS settings
$dns_hostmaster = "{{hostmaster_host}}";
$dns_ns1 = "{{primary_ns_host}}";
$dns_ns2 = "{{secondary_ns_host}}";

// Logging
$syslog_use = true;

// Security settings
$session_key = "{{poweradmin_session_key}}";
$password_encryption = "md5salt";

// DNSSEC
$pdnssec_use = true;
$pdnssec_command = "/usr/bin/pdnsutil";
