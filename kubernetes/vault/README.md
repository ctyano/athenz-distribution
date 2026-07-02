# Vault - HashiCorp Vault PKI Certificate Signer for Athenz

This component deploys [HashiCorp Vault](https://www.vaultproject.io/) as a PKI certificate signer for Athenz, compatible with both `VaultCertSigner` (Java plugin) and `athenz-user-cert` (Go client).

[![](https://img.plantuml.biz/plantuml/svg/VPJDJjj0483l-nIZzDQIEa6eL1mgGd0G9I9HRAXQMK8JUsflRUzQk-j0g7hj0_GH-oGTsoaaW90lrkutF_lDsiVMeN5rMGYRIrMXmHAM6EUfqRLAnhhG1jvC_ERP8c9TLbgHSl1J09neav3Pi0S7X_lZWsRrQHR_msGmcV3EH2iNo7k2uRxu9GJ6ZhT7IIcL41L7OKhGkwYNP1GviZ0kQkl8zDfY3y0AwyA1mf8ihr6t2rkjzQvR8Y2p8XEfIXi77_S7WqYDgcgX2m8FvXVdFK0BrwEhQVWq_aHhPvt1AbA1J2X6pj9L7K-xi9FPx5cKhrPw3NEZxzQReiF1eAawHsjTnaRIh0tsBwzdNvz6eyj8tVVZGaRgb9PrweLaNSjpqPPEqE4IBIkWidBhKybj6JxEZKmYPIasvFYrEzPioY7iUCjRL-5LSQCE-HO6aGfrJggLA1kMa_BoYwR7P7YigMfaVyOLmhoeKwaUTRzxq1sSdrtwYsUj-NSyPeN52orjlDIMJ3_cGf4wquqHBlKbX57jEgTNWRyO-ukmJSt9sri5_VwdRi9m13dVgzWLW5LLhA6Vyu9rkkJhA9ffxh1IIRS7DKl5Oe-xKTzbMfjjS3PbZExQCRFuX7kLM5ZHPMYGbZs27GTW29Er49s6dPBpMH22jnfwo4VokCbcibwXMUIhU9LBpx9yhnFr4dlcFw8ntiGPSix_mbgolP7FclXnwpODl0uR_bnYxBgGrjPahEYWxIwgviDe-RVmz_SV_WSSlX_mCpnglat18zt1CrRlCeWpYdDnJ2hXNzK_)](https://editor.plantuml.com/uml/VPJDJjj0483l-nIZzDQIEa6eL1mgGd0G9I9HRAXQMK8JUsflRUzQk-j0g7hj0_GH-oGTsoaaW90lrkutF_lDsiVMeN5rMGYRIrMXmHAM6EUfqRLAnhhG1jvC_ERP8c9TLbgHSl1J09neav3Pi0S7X_lZWsRrQHR_msGmcV3EH2iNo7k2uRxu9GJ6ZhT7IIcL41L7OKhGkwYNP1GviZ0kQkl8zDfY3y0AwyA1mf8ihr6t2rkjzQvR8Y2p8XEfIXi77_S7WqYDgcgX2m8FvXVdFK0BrwEhQVWq_aHhPvt1AbA1J2X6pj9L7K-xi9FPx5cKhrPw3NEZxzQReiF1eAawHsjTnaRIh0tsBwzdNvz6eyj8tVVZGaRgb9PrweLaNSjpqPPEqE4IBIkWidBhKybj6JxEZKmYPIasvFYrEzPioY7iUCjRL-5LSQCE-HO6aGfrJggLA1kMa_BoYwR7P7YigMfaVyOLmhoeKwaUTRzxq1sSdrtwYsUj-NSyPeN52orjlDIMJ3_cGf4wquqHBlKbX57jEgTNWRyO-ukmJSt9sri5_VwdRi9m13dVgzWLW5LLhA6Vyu9rkkJhA9ffxh1IIRS7DKl5Oe-xKTzbMfjjS3PbZExQCRFuX7kLM5ZHPMYGbZs27GTW29Er49s6dPBpMH22jnfwo4VokCbcibwXMUIhU9LBpx9yhnFr4dlcFw8ntiGPSix_mbgolP7FclXnwpODl0uR_bnYxBgGrjPahEYWxIwgviDe-RVmz_SV_WSSlX_mCpnglat18zt1CrRlCeWpYdDnJ2hXNzK_)

## Usage

### Deploy

```sh
make -C kubernetes deploy-vault
# or from project root:
make deploy-kubernetes-vault
```

### Access Vault UI

```sh
kubectl -n vault port-forward service/vault 8200:8200
```

Open [http://localhost:8200](http://localhost:8200) in your browser and log in with token `root`.

### OIDC Login (Dex — default)

> **Note:** Vault 2.0 changed the OIDC `auth_url` endpoint from GET to POST (requires `redirect_uri`).
> The Vault UI currently attempts to read role details before initiating login,
> which fails for unauthenticated users. Use the helper script below instead.

Port-forward Vault and Dex, then run the login script.

```sh
# Terminal 1: port-forward both
make -C kubernetes/vault port-forward

# Terminal 2: run login script
kubernetes/vault/kustomize/conf/oidc-login.sh
```

This will open your browser to the Dex login page. Sign in as `athenz_admin@athenz.io` / `password`.
After authenticating, you will be redirected back to Vault with an active session.

Alternatively, use curl directly:

```sh
AUTH_URL=$(curl -sf -X POST \
  -d "role=dex&redirect_uri=http://localhost:8200/v1/auth/dex/oidc/callback" \
  "http://127.0.0.1:8200/v1/auth/dex/oidc/auth_url" | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['data']['auth_url'])")
echo "$AUTH_URL"
open "$AUTH_URL"   # macOS
# xdg-open "$AUTH_URL"   # Linux
```

### OIDC Login (Keycloak — alternative)

Port-forward Vault and Keycloak:

```sh
# Terminal 1
kubectl -n vault port-forward service/vault 8200:8200

# Terminal 2
kubectl -n keycloak port-forward service/keycloakx-http 18080:80
```

Then use curl to initiate login:

```sh
AUTH_URL=$(curl -sf -X POST \
  -d "role=keycloak&redirect_uri=http://localhost:8200/v1/auth/keycloak/oidc/callback" \
  "http://127.0.0.1:8200/v1/auth/keycloak/oidc/auth_url" | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['data']['auth_url'])")
open "$AUTH_URL"   # macOS
```

To switch from Dex to Keycloak as the default OIDC provider, change the Vault bootstrap script:

```
# In bootstrap.sh, swap the primary auth mount:
default_role="keycloak"   # was: default_role="dex"
```

### Test

```sh
make -C kubernetes test-vault
make -C kubernetes test-vault-pki
```

### Clean

```sh
make -C kubernetes clean-vault
# or from project root:
make clean-kubernetes-vault
```

## Additional resources

- [Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [Vault PKI Secrets Engine](https://developer.hashicorp.com/vault/api-docs/secret/pki)
- [Athenz VaultCertSigner](https://github.com/ctyano/athenz-plugins)
- [athenz-user-cert](https://github.com/ctyano/athenz-user-cert)
