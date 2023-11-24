# Credential Preparation

## Root CA

```
make clean-certificates generate-ca
```

## ZMS Keys and Certificates

the default `generate-zms` requires `keytool`.

```
make generate-zms
```

or without keytool (without Java)

```
make generate-zms-with-docker
```

## ZTS Keys and Certificates

the default `generate-zts` requires `keytool`.

```
make generate-zts
```

or without keytool (without Java)

```
make generate-zts-with-docker
```

## Athenz Admin Keys and Certificates

```
make generate-admin
```

## Athenz UI Keys and Certificates

```
make generate-ui
```

