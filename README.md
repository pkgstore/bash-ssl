# Generating OpenSSL CA

Скрипт позволяет создавать уже готовый центр сертификации.

## OpenSSL Root CA

Корневой центр сертификации необходим только для подписания сертификата промежуточного центра сертификации.

### Синтаксис

```
bash ca.run.sh init_ca_root
```

### Структура

```sh
ca.root/
├── certs/
├── certs.new/
├── crl/
├── csr/
├── index.txt
├── private/
└── serial
```

## OpenSSL Intermediate CA

Промежуточный центр сертификации необходим для выпуска и подписания сертификатов серверов и пользователей.

### Синтаксис

```
bash ca.run.sh init_ca
```

### Структура

```sh
ca/
├── certs/
├── certs.new/
├── crl/
├── csr/
├── index.txt
├── private/
└── serial
```

## OpenSSL Server Certificate

Серверный сертификат устанавливается на сервер и используется службами сервера.

### Синтаксис

```
bash ca.run.sh gen_crt_srv '[CERT_FILE_NAME]'
```

## OpenSSL User Certificate

Пользовательский сертификат устанавливается у клиента и используется службами клиента.

### Синтаксис

```
bash ca.run.sh gen_crt_usr '[CERT_FILE_NAME]'
```
