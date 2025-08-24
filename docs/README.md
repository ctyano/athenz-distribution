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

# Explore the full showcase on Kubernetes
 
- [Showcases for Kubernetes](SHOWCASES_KUBERNETES.md)

[![](https://img.plantuml.biz/plantuml/svg/VLHDRzim3BthLn0-jGTZwBM7e6bt2RO1mxfYmBfWa6Kbrc9RhaGtJORyzr4VjjNMsI61pFSUzKHIkh783VPDpMgvGK0DHcqhX58PAL3fbZ4kK1l8bbZ9zWWFLfeCk8MU5ep-1BSIiX-oW5kZzmDQXFL4YFAxpokFYren9chTbv1zwWjfMedIXNkBBiLV1Y2u8LIOGxTJGMHy7A3LfHoGtEeDLhO931iP08y1NWUXMmv057WahZrqOk4NzWs6VLOUlATxXr3U1sFzjAihnCFAv-xLcFQDxDZOdAhp78jrdEG_lznxBJ7EYl6L61FnzoZ6i-AoyAAo65KbHrwaBVfucuqW9IKdlyDslzg1ErWiYuI7vtWuyKupXGvJq1dzhCfu9lgOgpRXBIeyvA_9Km7Y2LQH1ryZRnsJ-eyP2qPQtHiXGU_RcDMlvapm7Yjjr96xs-6Sl1p2a2HTNAOSkFTLyHwS-3YmlWsx9eJ1oMoT51qBUDU5KUTpxW8f42O_Tq6wxBfrl7pqcMnnOkwY6iWNmyM5Qz2TRDdmcHFKAufMYDr5hGMlAstnSjHHJaBbYnJCBHsV1YGABEL_5xjeiBQNZCRZ7D8u940qiDVG7EnJFGamZOxXeSs4P7jPL5hlGjOiK1RnDN2ua0RLHWcE4gpQjgfLMsh1KoyjPYpoI15V2P9qEs6lhjpJvIiQVRmnxhlyVsmnTdgcfcDoV_gWIBDy-BCdraXxh5H94xzE3i_6x2aQ-yvkP5kw9_yV)](https://editor.plantuml.com/uml/VLHDRzim3BthLn0-jGTZwBM7e6bt2RO1mxfYmBfWa6Kbrc9RhaGtJORyzr4VjjNMsI61pFSUzKHIkh783VPDpMgvGK0DHcqhX58PAL3fbZ4kK1l8bbZ9zWWFLfeCk8MU5ep-1BSIiX-oW5kZzmDQXFL4YFAxpokFYren9chTbv1zwWjfMedIXNkBBiLV1Y2u8LIOGxTJGMHy7A3LfHoGtEeDLhO931iP08y1NWUXMmv057WahZrqOk4NzWs6VLOUlATxXr3U1sFzjAihnCFAv-xLcFQDxDZOdAhp78jrdEG_lznxBJ7EYl6L61FnzoZ6i-AoyAAo65KbHrwaBVfucuqW9IKdlyDslzg1ErWiYuI7vtWuyKupXGvJq1dzhCfu9lgOgpRXBIeyvA_9Km7Y2LQH1ryZRnsJ-eyP2qPQtHiXGU_RcDMlvapm7Yjjr96xs-6Sl1p2a2HTNAOSkFTLyHwS-3YmlWsx9eJ1oMoT51qBUDU5KUTpxW8f42O_Tq6wxBfrl7pqcMnnOkwY6iWNmyM5Qz2TRDdmcHFKAufMYDr5hGMlAstnSjHHJaBbYnJCBHsV1YGABEL_5xjeiBQNZCRZ7D8u940qiDVG7EnJFGamZOxXeSs4P7jPL5hlGjOiK1RnDN2ua0RLHWcE4gpQjgfLMsh1KoyjPYpoI15V2P9qEs6lhjpJvIiQVRmnxhlyVsmnTdgcfcDoV_gWIBDy-BCdraXxh5H94xzE3i_6x2aQ-yvkP5kw9_yV)

# Learn More

Visit the official Athenz website: [www.athenz.io](http://www.athenz.io)  

## Learn how to use Athenz in practice

- [How to generate keys and certificates](CERTIFICATES.md)
 
- [CLI instruction](CLI.md)
 
- [How to generate keys and retrieve certificates (**Identity Provisioning**)](IDENTITYPROVISIONING.md)

- [Envoy Ambassador Instruction for Kubernetes](ENVOY.md)

