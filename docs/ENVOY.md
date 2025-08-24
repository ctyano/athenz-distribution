# Envoy Ambassador Instruction for Kubernetes

## Deployment Instructions

### [athenz-identityprovider](../kubernetes/athenz-identityprovider)

Envoy configuration: [config.yaml](../kubernetes/athenz-identityprovider/kustomize/envoy/config.yaml)

### [athenz-authorizer](../kubernetes/athenz-authorizer)

Envoy configuration: [config.yaml](../kubernetes/athenz-authorizer/kustomize/envoy/config.yaml)

### [athenz-authzenvoy](../kubernetes/athenz-authzenvoy)

Envoy configuration: [config.yaml](../kubernetes/athenz-authzenvoy/kustomize/envoy/config.yaml)

### [athenz-authzwebhook](../kubernetes/athenz-authzwebhook)

Envoy configuration: [config.yaml](../kubernetes/athenz-authzwebhook/kustomize/envoy/config.yaml)

### [athenz-client](../kubernetes/athenz-client)

Envoy configuration: [config.yaml](../kubernetes/athenz-client/kustomize/envoy/config.yaml)

## How to try them out

Setup [Kubernetes Showcase](https://github.com/ctyano/athenz-distribution/blob/main/docs/SHOWCASES_KUBERNETES.md#full-setup-on-a-kubernetes-cluster-) as prerequisite.

### client2echoserver

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2echoserver.html)

[![](https://img.plantuml.biz/plantuml/svg/LS-x3i8m38NXFKznn8egTWRKoskmHAdR14A2RFVwzAYb0spMP-cNJYbgMOTND94wXMPmwBsY3KnEGqx6R8TDVIIStC3n12keVfLw9X6u62Wftfpd1PJ6lDpJ5DI3PhM3-XLTY4fygEOd9KXeoLdUe_LVrFain2DzVuqn5OhYXXfNUDMtN3IAgNTh3iCPZqalwvusfgJKRii-)](https://editor.plantuml.com/uml/LS-x3i8m38NXFKznn8egTWRKoskmHAdR14A2RFVwzAYb0spMP-cNJYbgMOTND94wXMPmwBsY3KnEGqx6R8TDVIIStC3n12keVfLw9X6u62Wftfpd1PJ6lDpJ5DI3PhM3-XLTY4fygEOd9KXeoLdUe_LVrFain2DzVuqn5OhYXXfNUDMtN3IAgNTh3iCPZqalwvusfgJKRii-)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2echoserver | jq -r .request"
```

### client2extauthz

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2extauthz.html)

[![](https://img.plantuml.biz/plantuml/svg/ZP2zRiCm38HtFiKXQn5axr0aTXwZYo0p5bjL2aWwFtxwrae6P-j6V7VuSE3UFAXFFvaodnnUeJ8cno3AqQKMekK8PSoCJPmqRn0CXpNbKTaCCGiNnrdhxGukbth_B5Vn1Bvvc3pDE4bsrYVr-iq59WF7e4tQhQLI7bPZlR3-sxgWgZA7PVkBlN-P75Dzc5js93fWk_r0XtSazxFjF1jrZVLhXZTyNNqtj_NKjyBnMVZB4eU1rOZsN8Rbgxy0)](https://editor.plantuml.com/uml/ZP2zRiCm38HtFiKXQn5axr0aTXwZYo0p5bjL2aWwFtxwrae6P-j6V7VuSE3UFAXFFvaodnnUeJ8cno3AqQKMekK8PSoCJPmqRn0CXpNbKTaCCGiNnrdhxGukbth_B5Vn1Bvvc3pDE4bsrYVr-iq59WF7e4tQhQLI7bPZlR3-sxgWgZA7PVkBlN-P75Dzc5js93fWk_r0XtSazxFjF1jrZVLhXZTyNNqtj_NKjyBnMVZB4eU1rOZsN8Rbgxy0)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2extauthz | jq -r .request"
```

### client2extauthzmtls

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2extauthzmtls.html)

[![](https://img.plantuml.biz/plantuml/svg/ZP2xZW8n34LxVyKLxGhHRu5WXi_O9igOITYG8DlXCL-_J408kksiSw-ER6_Kd5Wz9agyDrY1n34OXYZiBPPCD0ykZucny5NI0awnVQSy2gl2fyZPS99olO7pkTn-yYLQ05_DLGiJzZ4PovDQ-UKCZGDx9qtQlKjZVbYLvSpoR-kCYiJ9pRj_sFkFbNqe3tFBTaHRB9ThTFX6C3lfof9IrrZ_OiTgrINS8tpXSB7Lr8wWllLspzuz2-m65YNQS1xcv_u1)](https://editor.plantuml.com/uml/ZP2xZW8n34LxVyKLxGhHRu5WXi_O9igOITYG8DlXCL-_J408kksiSw-ER6_Kd5Wz9agyDrY1n34OXYZiBPPCD0ykZucny5NI0awnVQSy2gl2fyZPS99olO7pkTn-yYLQ05_DLGiJzZ4PovDQ-UKCZGDx9qtQlKjZVbYLvSpoR-kCYiJ9pRj_sFkFbNqe3tFBTaHRB9ThTFX6C3lfof9IrrZ_OiTgrINS8tpXSB7Lr8wWllLspzuz2-m65YNQS1xcv_u1)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2extauthzmtls | jq -r .request"
```

### client2authzproxy

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2authzproxy.html)

[![](https://img.plantuml.biz/plantuml/svg/LP2xRiCm34LtViL5riB8tY58R7z65q5cB3MA591q7lxwnee7ToCEBmy97jMSs7HDbFXii0A9Op0CKTXRB9beALmU4sFd9qaxECLfItaKLeLFaRFX9kNv0kTxUVtaHxG0VfgRBCmunsGiAxLouGoD0tidLTfkfSj4aJYxvOYcIcke-xVPXw8iT_u8Ug8JckQ05jy8PZVTMr9gA-ks35_uVTX-haTGLmFz6dZt0hk1HOcEd8VbENy0)](https://editor.plantuml.com/uml/LP2xRiCm34LtViL5riB8tY58R7z65q5cB3MA591q7lxwnee7ToCEBmy97jMSs7HDbFXii0A9Op0CKTXRB9beALmU4sFd9qaxECLfItaKLeLFaRFX9kNv0kTxUVtaHxG0VfgRBCmunsGiAxLouGoD0tidLTfkfSj4aJYxvOYcIcke-xVPXw8iT_u8Ug8JckQ05jy8PZVTMr9gA-ks35_uVTX-haTGLmFz6dZt0hk1HOcEd8VbENy0)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli — /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2authzproxy | jq -r .request"
```

### tokensidecar

[Load Test Result](https://ctyano.github.io/athenz-distribution/tokensidecar.html)

[![](https://img.plantuml.biz/plantuml/svg/JOux2iCm40NxFSN3RJ3fKmH_JYAaZIIYI6Pt7UpR1viKxXxpffX1pOcjdqA5NmPha1oJ8MHXRxbLecEu6WkZywkK3aunNYb7OLNuahaQ5cdR3gxVjf_gT5MjlRb2Ss3lvBndeX5z_yI41vBPedShIjF9vZ_33ObTO56YWMiuUdy0)](https://editor.plantuml.com/uml/JOux2iCm40NxFSN3RJ3fKmH_JYAaZIIYI6Pt7UpR1viKxXxpffX1pOcjdqA5NmPha1oJ8MHXRxbLecEu6WkZywkK3aunNYb7OLNuahaQ5cdR3gxVjf_gT5MjlRb2Ss3lvBndeX5z_yI41vBPedShIjF9vZ_33ObTO56YWMiuUdy0)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r ."
```

### authorizationsidecar

[Load Test Result](https://ctyano.github.io/athenz-distribution/authorizationsidecar.html)

[![](https://img.plantuml.biz/plantuml/svg/JS-z3eCm30JWtKznOgqGUuUAdoU9m2LfqmJPXXQUlWLrOBFkFftaMis9pQz8aUy6ov0mUiCGX7iBEH7jXqjZP1JzBB60KpJdDAHHM1NAih1WalnPmMd9ws7RitMp-InXS_isD0pSEpbOHzIWB6zeSOKtcxIogBZWyRPgi_paHEq1kZ_uTPxTmA94DQTX_-8B)](https://editor.plantuml.com/uml/JS-z3eCm30JWtKznOgqGUuUAdoU9m2LfqmJPXXQUlWLrOBFkFftaMis9pQz8aUy6ov0mUiCGX7iBEH7jXqjZP1JzBB60KpJdDAHHM1NAih1WalnPmMd9ws7RitMp-InXS_isD0pSEpbOHzIWB6zeSOKtcxIogBZWyRPgi_paHEq1kZ_uTPxTmA94DQTX_-8B)

with Role Token:

```
roletoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .roletoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Athenz-Role-Auth: $roletoken\" -H \"X-Athenz-Action: get\" -H \"X-Athenz-Resource: /server\" https://authorizer.athenz.svc.cluster.local/authorizationsidecar | jq -r ."
```

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" -H \"X-Athenz-Action: get\" -H \"X-Athenz-Resource: /server\" https://authorizer.athenz.svc.cluster.local/authorizationsidecar | jq -r ."
```

### authzproxy(authorization-proxy)

[Load Test Result](https://ctyano.github.io/athenz-distribution/authzproxy.html)

[![](https://img.plantuml.biz/plantuml/svg/JSux3iCW40JGVa-nSXiXzoaY6vy4mSQG4B2M9H-VFW6bS3UQUSLCHGnBVKI8T1MKZ1nMB-W2avMG4q0B9gsHSB2Luu2cu7niJHMVEUocURLnVdywqaT4rkT2_2Jksm8mer8Nr7X6BxALKMB14zvUCkwIxvH0Tx3ymM_pP1nn0PWekVRv2m00)](https://editor.plantuml.com/uml/JSux3iCW40JGVa-nSXiXzoaY6vy4mSQG4B2M9H-VFW6bS3UQUSLCHGnBVKI8T1MKZ1nMB-W2avMG4q0B9gsHSB2Luu2cu7niJHMVEUocURLnVdywqaT4rkT2_2Jksm8mer8Nr7X6BxALKMB14zvUCkwIxvH0Tx3ymM_pP1nn0PWekVRv2m00)

with Role Token:

```
roletoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: authorization-proxy-clients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .roletoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Athenz-Role-Auth: $roletoken\" https://authzproxy.athenz.svc.cluster.local/echoserver | jq -r .request"
```

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: authorization-proxy-clients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" https://authzproxy.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### client2filterauthzmtls

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2filterauthzmtls.html)

[![](https://img.plantuml.biz/plantuml/svg/RP31QiCm38RlVegVNalPVOUI9dsCNOoZn6QgNIGvRVVq8sue7UmclWzz27LgNgnUs35D1YkGD4V3c8I2fPATMmUVPoRiGXNUmIjExvHc8LK4JfGDLodt1oWlvV6LRyaYw6w-Mlp1bDX8Dchbcp8qZHIyj6Z_7atvMLMIXUIVAbU_1TloyEUY4CjpiRcpSoSS3aVq-4Gqk-g7iRg-iU75BjMgPwngQEgyAUmHoOyawbn7ULpVzGi0)](https://editor.plantuml.com/uml/RP31QiCm38RlVegVNalPVOUI9dsCNOoZn6QgNIGvRVVq8sue7UmclWzz27LgNgnUs35D1YkGD4V3c8I2fPATMmUVPoRiGXNUmIjExvHc8LK4JfGDLodt1oWlvV6LRyaYw6w-Mlp1bDX8Dchbcp8qZHIyj6Z_7atvMLMIXUIVAbU_1TloyEUY4CjpiRcpSoSS3aVq-4Gqk-g7iRg-iU75BjMgPwngQEgyAUmHoOyawbn7ULpVzGi0)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2filterauthzmtls | jq -r .request"
```

### client2filterauthzjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2filterauthzjwt.html)

[![](https://img.plantuml.biz/plantuml/svg/RP2nRiCm34HtViKXQs1axn0aTZwZYo0pbbf52aZQIVhrZMKFBj2DU8TxEF2aviJ6MwB4LuCLI1o2eO_2tcB9HFFXyf0OEpzAsi4fpblAWx0gV8gS3NSfpnSuJ-NrcH_H0lXfRhJmWsjCnh9IAz-SeR5dxwHAswqqviMgB1FBFzQlXwt2Mkx-BFAXBCMQNOZEQ9eZMdmWcDtrO4cfhQpRCkndBtKrkQp96mPsFOiIdJZtyxT-0G00)](https://editor.plantuml.com/uml/RP2nRiCm34HtViKXQs1axn0aTZwZYo0pbbf52aZQIVhrZMKFBj2DU8TxEF2aviJ6MwB4LuCLI1o2eO_2tcB9HFFXyf0OEpzAsi4fpblAWx0gV8gS3NSfpnSuJ-NrcH_H0lXfRhJmWsjCnh9IAz-SeR5dxwHAswqqviMgB1FBFzQlXwt2Mkx-BFAXBCMQNOZEQ9eZMdmWcDtrO4cfhQpRCkndBtKrkQp96mPsFOiIdJZtyxT-0G00)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2filterauthzjwt | jq -r .request"
```

### client2filterauthzmtlsjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2filterauthzmtlsjwt.html)

[![](https://img.plantuml.biz/plantuml/svg/RT3FYW8n3CVnUv_YXzT5zkv1TCR7y58wSThTs4gI-k_fTUgmAEojV1C-X6xKl5WzicCw6An0qXWDGn8AbafsRdhuF39X4Qhm0bwnVQyq2gaYSA9iE4cvta3vN6xxV4aMGLVprU8TXyH6CbShlvIXQQ3WfQ7TEvhoIrMICya_AbV_2VvSR0vDwpzE3B6yf3RRERV5Shb6XnMYsKc_ZTLrhVL_xLYjUiPpXA-9TtrRsCqBpnZ93oJgt8RoCFtY0m00)](https://editor.plantuml.com/uml/RT3FYW8n3CVnUv_YXzT5zkv1TCR7y58wSThTs4gI-k_fTUgmAEojV1C-X6xKl5WzicCw6An0qXWDGn8AbafsRdhuF39X4Qhm0bwnVQyq2gaYSA9iE4cvta3vN6xxV4aMGLVprU8TXyH6CbShlvIXQQ3WfQ7TEvhoIrMICya_AbV_2VvSR0vDwpzE3B6yf3RRERV5Shb6XnMYsKc_ZTLrhVL_xLYjUiPpXA-9TtrRsCqBpnZ93oJgt8RoCFtY0m00)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2filterauthzmtlsjwt | jq -r .request"
```

### envoyjwtfilter(jwt filter/lua filter)

[Load Test Result](https://ctyano.github.io/athenz-distribution/envoyjwtfilter.html)

[![](https://img.plantuml.biz/plantuml/svg/JOyx3eCm40NxFSLJsWYbJn7nkKOQ2nRioB7HxWBXzWc4WkvfHXhfbMfER7f7YjmRB4F2u0rT46ujv4Iq3PU6oBYqayGBdA8wqv06OLKeoyo2KV9d1QSvhy-q1FE8aqCVeh4SuBNO0VPQVQvnw_E_jBk6g49HF53Z3cyswisYuhergDvDSvWVzEmw5YKgENNRgoy0)](https://editor.plantuml.com/uml/JOyx3eCm40NxFSLJsWYbJn7nkKOQ2nRioB7HxWBXzWc4WkvfHXhfbMfER7f7YjmRB4F2u0rT46ujv4Iq3PU6oBYqayGBdA8wqv06OLKeoyo2KV9d1QSvhy-q1FE8aqCVeh4SuBNO0VPQVQvnw_E_jBk6g49HF53Z3cyswisYuhergDvDSvWVzEmw5YKgENNRgoy0)

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" https://authzenvoy.athenz.svc.cluster.local/jwtauthn | jq -r .request"
```

### client2webhookauthzmtls

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2webhookauthzmtls.html)

[![](https://img.plantuml.biz/plantuml/svg/RP7DRi8m40RlVefFN2lKUmyL9F0MlHXd4riO6-sk-NjwY4FR876pPhIpbdObQbdB8Pf8lK8pE0nUqGKcfo4dOyQ7JKCaB5pXk80LhEUK1YOHk1WeAOwSBrTGEkNhJpe7zQ2BsgB-XZv49NvIpNjAaD2HiroZpJmQqbGLuXFncseizZNu3z1dnaq5qzepxNpE-xgZVVcuytdgLxUPkyTuXLjZrbWklz7W2rxrA9yQnJILjN_iKBJOY56rLMsU2X_mP3lYNx5zDsDMbBhn2dS0)](https://editor.plantuml.com/uml/RP7DRi8m40RlVefFN2lKUmyL9F0MlHXd4riO6-sk-NjwY4FR876pPhIpbdObQbdB8Pf8lK8pE0nUqGKcfo4dOyQ7JKCaB5pXk80LhEUK1YOHk1WeAOwSBrTGEkNhJpe7zQ2BsgB-XZv49NvIpNjAaD2HiroZpJmQqbGLuXFncseizZNu3z1dnaq5qzepxNpE-xgZVVcuytdgLxUPkyTuXLjZrbWklz7W2rxrA9yQnJILjN_iKBJOY56rLMsU2X_mP3lYNx5zDsDMbBhn2dS0)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2webhookauthzmtls | jq -r .request"
```

### client2webhookauthzjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2webhookauthzjwt.html)

[![](https://img.plantuml.biz/plantuml/svg/RP51Ri8m44NtFiKNsmfrtqK52ToY6zUPn2x6HZDZ0fo-n8cg87LdlQTvCv9tefQrdAE9r2iqWyFW5LrWSXfoCcPws3H4miOLZXjOmNvDQM0IWOk1akB2-NO7fMk-VwKng0VTr1Rr3_GXAl52DPyeGK97pdADDkjeI7DLYA_4_rH_HdqDnc8NW3up7YgOruxqxNC-rHtjo-7EvxbVtM7jdkCL7etPOxlzH8CFUDMBl6iKqrJMhXdUffjCMyrXCK_eoNR4ieZZtyYvQB4HKytiA7NJ9_m2)](https://editor.plantuml.com/uml/RP51Ri8m44NtFiKNsmfrtqK52ToY6zUPn2x6HZDZ0fo-n8cg87LdlQTvCv9tefQrdAE9r2iqWyFW5LrWSXfoCcPws3H4miOLZXjOmNvDQM0IWOk1akB2-NO7fMk-VwKng0VTr1Rr3_GXAl52DPyeGK97pdADDkjeI7DLYA_4_rH_HdqDnc8NW3up7YgOruxqxNC-rHtjo-7EvxbVtM7jdkCL7etPOxlzH8CFUDMBl6iKqrJMhXdUffjCMyrXCK_eoNR4ieZZtyYvQB4HKytiA7NJ9_m2)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2webhookauthzjwt | jq -r .request"
```

### client2webhookauthzmtlsjwt

[Load Test Result](https://ctyano.github.io/athenz-distribution/client2webhookauthzmtlsjwt.html)

[![](https://img.plantuml.biz/plantuml/svg/RP71Zi8m34Jl-OeHrnNQ-nvMqC9Vx2MRkasMa237eS3NRvjMq4hSh3VZiItlacYMVFRAKokG27QT5JIEoOYBGQcnqA7pX8t9x3VG2VibfOuf9HZlA0Wk76ztKBZ6-q_edLZGJNGM-q3hl13FLEA90f9ho6WkeTKor8KfDH5VYT-a-gpNWN-zhC7BWJOo7f8mxT7JhutnL8RMgqkCZTF0eXsMsj1Uu56fFRRRRrJuWXMvf4_nILM5rKzspfArno3XOrnDrSLmc0q3jAGRuZGBnpUTIkqeDEDp_W40)](https://editor.plantuml.com/uml/RP71Zi8m34Jl-OeHrnNQ-nvMqC9Vx2MRkasMa237eS3NRvjMq4hSh3VZiItlacYMVFRAKokG27QT5JIEoOYBGQcnqA7pX8t9x3VG2VibfOuf9HZlA0Wk76ztKBZ6-q_edLZGJNGM-q3hl13FLEA90f9ho6WkeTKor8KfDH5VYT-a-gpNWN-zhC7BWJOo7f8mxT7JhutnL8RMgqkCZTF0eXsMsj1Uu56fFRRRRrJuWXMvf4_nILM5rKzspfArno3XOrnDrSLmc0q3jAGRuZGBnpUTIkqeDEDp_W40)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/client2webhookauthzmtlsjwt | jq -r .request"
```

### envoywebhook(jwt filter/lua filter/lua filter for zts authz webhook)

[Load Test Result](https://ctyano.github.io/athenz-distribution/envoywebhook.html)

[![](https://img.plantuml.biz/plantuml/svg/LP113e8m44NtFSMFMsFSkp2A7iDDXO5MQsjcfg2UNa2Yk6lUcv-NT2TgMVCjc42rGXFODqvHUQPIVOh630yRcq1Ob9d30bQmdrCV6oOH275BZ3kdnnCKs_GynSwhGyWMjGzAF85Bf__WTu4wCLugi5dT2nsTNKhNCLhCerIwz0cExZ1t_No4HsFsMAssAB21KxtBMeDWEVHDCPh3P7heo5R4CedZTtBBccr0lpHcHx4QFkiD)](https://editor.plantuml.com/uml/LP113e8m44NtFSMFMsFSkp2A7iDDXO5MQsjcfg2UNa2Yk6lUcv-NT2TgMVCjc42rGXFODqvHUQPIVOh630yRcq1Ob9d30bQmdrCV6oOH275BZ3kdnnCKs_GynSwhGyWMjGzAF85Bf__WTu4wCLugi5dT2nsTNKhNCLhCerIwz0cExZ1t_No4HsFsMAssAB21KxtBMeDWEVHDCPh3P7heo5R4CedZTtBBccr0lpHcHx4QFkiD)

with Access Token:

```
accesstoken=$(kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -s -H\"X-Athenz-Domain: athenz\" -H\"X-Athenz-Role: envoyclients\" https://client.athenz.svc.cluster.local/tokensidecar | jq -r .accesstoken | xargs echo -n")
```

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv -H \"Authorization: Bearer $accesstoken\" https://authzwebhook.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### echoserver(client)

[Load Test Result](https://ctyano.github.io/athenz-distribution/echoserver.client.html)

[![](https://img.plantuml.biz/plantuml/svg/LOux2iCm40NxFSN3RJ3fKmH_JYAaZILG9BExDl7jZKMAf7lCcs86DIUslJDbVXciGj8I3I49Uqkr45t3bIKpEhz9xk0Kuo_bHLWLFYSkXbNgvm2NlHvDdVvK7wkox2pjcub6zFqJ4nw8PglUBIjDZSrVXXiYky2YH0ENSCMU)](https://editor.plantuml.com/uml/LOux2iCm40NxFSN3RJ3fKmH_JYAaZILG9BExDl7jZKMAf7lCcs86DIUslJDbVXciGj8I3I49Uqkr45t3bIKpEhz9xk0Kuo_bHLWLFYSkXbNgvm2NlHvDdVvK7wkox2pjcub6zFqJ4nw8PglUBIjDZSrVXXiYky2YH0ENSCMU)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### echoserver(authorizer)

[Load Test Result](https://ctyano.github.io/athenz-distribution/echoserver.authorizer.html)

[![](https://img.plantuml.biz/plantuml/svg/LOun3i8m40JxUyKgBOheAL3YlCHA3jkIiQExIqH-Zs8ee5lDJZ63cXVRdfaoFmnM8Ib4mvA4Pqkr49t3bv0PtRn9xk0Luo_b8AmAPTbPi4fz7U2orwEfxa-TO_ruxPk8HlJz7GutHBDLhvQLN6FJb-62o7vXKQA1otB6lW40)](https://editor.plantuml.com/uml/LOun3i8m40JxUyKgBOheAL3YlCHA3jkIiQExIqH-Zs8ee5lDJZ63cXVRdfaoFmnM8Ib4mvA4Pqkr49t3bv0PtRn9xk0Luo_b8AmAPTbPi4fz7U2orwEfxa-TO_ruxPk8HlJz7GutHBDLhvQLN6FJb-62o7vXKQA1otB6lW40)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://authorizer.athenz.svc.cluster.local/echoserver | jq -r .request"
```

### zms(authorization management service)

[Load Test Result](https://ctyano.github.io/athenz-distribution/zms.html)

[![](https://img.plantuml.biz/plantuml/svg/JOux3eD030Lxd-A97gLF4V4voGeSMCdi8jkB0gT7K4HqJ_EccCOyg9T5IFZhy0oDq-mOe_BWCIUYQuGq2QCQYag5O6YVb2TbCmmIEJbMpRyTdBQytshtL8FFd0uSYy5ODzPRwObQrFK77TwOtLTxkHXrD-l_R2bUWk2wgE4qNjKd)](https://editor.plantuml.com/uml/JOux3eD030Lxd-A97gLF4V4voGeSMCdi8jkB0gT7K4HqJ_EccCOyg9T5IFZhy0oDq-mOe_BWCIUYQuGq2QCQYag5O6YVb2TbCmmIEJbMpRyTdBQytshtL8FFd0uSYy5ODzPRwObQrFK77TwOtLTxkHXrD-l_R2bUWk2wgE4qNjKd)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/zms/v1/domain/sys.auth/service | jq -r ."
```

### zts(authorization token service)

[Load Test Result](https://ctyano.github.io/athenz-distribution/zts.html)

[![](https://img.plantuml.biz/plantuml/svg/JOux3eD030Lxd-A97gLF4V4voGeSMCdi8jkB0gT7K4HqJ_EccCOyg9T5IFZhy0oDq-mOe_BWCIUYQuGq2QCQYag5O6YVb2TbCmmIEJbMpRyTdBQytshtL8FFd0uSRZ3MZVLMUg8MTVr1XpTczzLUBaRTpVe_MugN8BWkQZYDL_K9)](https://editor.plantuml.com/uml/JOux3eD030Lxd-A97gLF4V4voGeSMCdi8jkB0gT7K4HqJ_EccCOyg9T5IFZhy0oDq-mOe_BWCIUYQuGq2QCQYag5O6YVb2TbCmmIEJbMpRyTdBQytshtL8FFd0uSRZ3MZVLMUg8MTVr1XpTczzLUBaRTpVe_MugN8BWkQZYDL_K9)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/zts/v1/domain/sys.auth/service | jq -r ."
```

### client(metrics)

prometheus metrics

[![](https://img.plantuml.biz/plantuml/svg/JOun2iCm40JxUyNYtgXF4Mo_8usGBv90FXdTASI_jvqgtJ0moqvglbdV2XL-6woYvPWCQsuSB5SXki5BB8mXz5O6UCNyRpasLaKecSMmj_ezmFAfnqlSDM_gBhUn9UxwgnUY6UFun887ajckpeeIJIphVUK4)](https://editor.plantuml.com/uml/JOun2iCm40JxUyNYtgXF4Mo_8usGBv90FXdTASI_jvqgtJ0moqvglbdV2XL-6woYvPWCQsuSB5SXki5BB8mXz5O6UCNyRpasLaKecSMmj_ezmFAfnqlSDM_gBhUn9UxwgnUY6UFun887ajckpeeIJIphVUK4)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://client.athenz.svc.cluster.local/stats/prometheus"
```

### server(metrics)

prometheus metrics

[![](https://img.plantuml.biz/plantuml/svg/JOun3eCm40JxUyMA7hbF4G7lI6F11LioPtHtHk7tWLJfHYFDQWVpgDwsGeNV3g_Gl2R7afLdprM8ReYo5aOtDoqTec7yjrbMPJCOwy6ANUld1CjHpvU4QzyjN6vZJzpibqz48_h-YGaF9FVTWXSZ6bYM-yiN)](https://editor.plantuml.com/uml/JOun3eCm40JxUyMA7hbF4G7lI6F11LioPtHtHk7tWLJfHYFDQWVpgDwsGeNV3g_Gl2R7afLdprM8ReYo5aOtDoqTec7yjrbMPJCOwy6ANUld1CjHpvU4QzyjN6vZJzpibqz48_h-YGaF9FVTWXSZ6bYM-yiN)

```
kubectl -n athenz exec -it deployment/athenz-cli -c athenz-cli -- /bin/sh -c "curl -sv https://authorizer.athenz.svc.cluster.local/stats/prometheus"
```

