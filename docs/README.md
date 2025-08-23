# About athenz-distribution repository

The documents describe the varieties of use-cases to implement authorization between pods inside a cluster.

# Introduction

[Athenz](http://www.athenz.io) is an open-source project, currently a CNCF sandbox project, that provides:  
- **Authentication** using SPIFFE-compatible X.509 certificates or OAuth 2.0-based access tokens.  
- **Authorization** through role-based access control (RBAC) for cloud workloads, including Kubernetes.  

# Why Athenz?

In multi-cluster or multi-cloud environments, precise and frequently configurable access control policies are crucial. Athenz simplifies this process with:  
- **Web UI, CLI, and REST API** for managing policies.  
- **Automated deployment** of policies to workloads via Athenz agents.  

[![](https://img.plantuml.biz/plantuml/svg/TLFBJiCm4BpxArQvvnUgFhXKW8Ge5HAbGaviMajf73dhGeFwxwnVIGhj8Uq-PjRZpMJQ8ZTe3nMhv2S2QZ1gjqSGoiWIbQuPuoLg0zaCzxBkODrAam5lmLB0wAVahOJiLHOmD_ehTOiG3u18NpmiVR-i56DbfQs0xDuMqjGIfIlR5js87mPGSYCIqPDucE5w0BKMD3QKSgk2fjW3s3X1w-NMLvKldl_JkaERayfZ5DqDzBV7bUSIuYOPByWu8hz4CjuaYyAJHD6p14TUZ5TrDy_w9Wqb9H_XkFSwOPD4KOnmU0k70-xSwtBFXJ8bP8qAJtbZz96ISBicIjb4SSk8WgU8yaSaohMvtE9U6zLnvoet_FiKNchNZnuZOENluCSwQXSmpxBLrfHot3QnTkrKyXa93PPBvony3MPDiurMfDIJpymPra0-wGqS_o6d6XafjPr_wN6XimYpoYDSJ7iUueEBGqBBxrl-LOHqCcmjA4a8vg_zDviCrnt1muROLDR2VSk_)](https://editor.plantuml.com/uml/TLFBJiCm4BpxArQvvnUgFhXKW8Ge5HAbGaviMajf73dhGeFwxwnVIGhj8Uq-PjRZpMJQ8ZTe3nMhv2S2QZ1gjqSGoiWIbQuPuoLg0zaCzxBkODrAam5lmLB0wAVahOJiLHOmD_ehTOiG3u18NpmiVR-i56DbfQs0xDuMqjGIfIlR5js87mPGSYCIqPDucE5w0BKMD3QKSgk2fjW3s3X1w-NMLvKldl_JkaERayfZ5DqDzBV7bUSIuYOPByWu8hz4CjuaYyAJHD6p14TUZ5TrDy_w9Wqb9H_XkFSwOPD4KOnmU0k70-xSwtBFXJ8bP8qAJtbZz96ISBicIjb4SSk8WgU8yaSaohMvtE9U6zLnvoet_FiKNchNZnuZOENluCSwQXSmpxBLrfHot3QnTkrKyXa93PPBvony3MPDiurMfDIJpymPra0-wGqS_o6d6XafjPr_wN6XimYpoYDSJ7iUueEBGqBBxrl-LOHqCcmjA4a8vg_zDviCrnt1muROLDR2VSk_)
<!--
https://editor.plantuml.com/uml/TLFBJiCm4BpxArQvvnUgFhXKW8Ge5HAbGaviMajf73dhGeFwxwnVIGhj8Uq-PjRZpMJQ8ZTe3nMhv2S2QZ1gjqSGoiWIbQuPuoLg0zaCzxBkODrAam5lmLB0wAVahOJiLHOmD_ehTOiG3u18NpmiVR-i56DbfQs0xDuMqjGIfIlR5js87mPGSYCIqPDucE5w0BKMD3QKSgk2fjW3s3X1w-NMLvKldl_JkaERayfZ5DqDzBV7bUSIuYOPByWu8hz4CjuaYyAJHD6p14TUZ5TrDy_w9Wqb9H_XkFSwOPD4KOnmU0k70-xSwtBFXJ8bP8qAJtbZz96ISBicIjb4SSk8WgU8yaSaohMvtE9U6zLnvoet_FiKNchNZnuZOENluCSwQXSmpxBLrfHot3QnTkrKyXa93PPBvony3MPDiurMfDIJpymPra0-wGqS_o6d6XafjPr_wN6XimYpoYDSJ7iUueEBGqBBxrl-LOHqCcmjA4a8vg_zDviCrnt1muROLDR2VSk_
-->

## Getting Started with Athenz  

Athenz is a powerful solution, but getting started should be straightforward!
Many new users find the initial setup complex, making experimentation difficult.  

This repository is here to **simplify the process** and help you:  
- **Set up Athenz quickly** with step-by-step guidance.  
- **Understand core concepts** through practical examples.  
- **Integrate Athenz with Kubernetes and Envoy proxy** seamlessly.  

Start exploring today and take full control of your cloud access management with Athenz!  

# Athenz packages
  
- [List of Athenz package distribution](DISTRIBUTIONS.md)

# Learn More

Visit the official Athenz website: [www.athenz.io](http://www.athenz.io)  

## Learn how to use Athenz in practice

- [How to generate keys and certificates](CERTIFICATES.md)
 
- [CLI instruction](CLI.md)
 
- [How to generate keys and retrieve certificates (**Identity Provisioning**)](IDENTITYPROVISIONING.md)

- [Envoy Ambassador Instruction for Kubernetes](ENVOY.md)
 
- [Showcases for Kubernetes](SHOWCASES_KUBERNETES.md)

