<?php
// Namingo v1.0.34 epp/config.php as used for the Module 9 test lab (2026-10-21).
// Lab-only values; replace the password. Port 700 needs root or CAP_NET_BIND_SERVICE.
return [
    'db_type' => 'mysql',            // MariaDB; the PostgreSQL path fails transfer approve (Namingo v1.0.34)
    'db_host' => '127.0.0.1',
    'db_port' => 3306,
    'db_database' => 'registry',
    'db_username' => 'registry',
    'db_password' => 'CHANGE-ME',
    'epp_host' => '0.0.0.0',
    'epp_port' => 700,
    'epp_pid' => '/var/run/epp.pid',
    'epp_greeting' => 'Lab EPP Server',
    'epp_prefix' => 'lab',
    'ssl_cert' => '/opt/registry/epp/epp.crt',   // signed by the lab CA; CN/SAN epp.registry.example
    'ssl_key' => '/opt/registry/epp/epp.key',
    'test_tlds' => '.test,.com.test',
    'rately' => false,
    'limit' => 1000,
    'period' => 60,
    'minimum_data' => false,
    'dnssec_keydata_digest_type' => 2,
    'ns_mode' => 'hostObj',
    'epp_max_frame' => 4 * 1024 * 1024,
    'disable_60days' => true,        // lab only: allow transfers of domains created minutes ago
    'mandatory_client_ssl' => true,  // RFC 5734 mutual authentication; registrar.ssl_fingerprint = SHA-256 of the client cert (DER, upper-case hex)
    'ssl_client_ca' => '/opt/registry/epp/lab-ca.crt',
];
