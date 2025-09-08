# About athenz-distribution repository

The documents describe the varieties of use-cases to implement authorization between pods inside a cluster.

# Introduction

[Athenz](http://www.athenz.io) is an open-source project, currently a CNCF sandbox project, that provides:  
- **Authentication** using SPIFFE-compatible X.509 certificates or OAuth 2.0-based access tokens.  
- **Authorization** through role-based access control (RBAC) for cloud workloads, including Kubernetes.  

[![](https://img.plantuml.biz/plantuml/svg/RL9DJy904BtlhvZqf8V6kmT2HOqQZOIMS10FotQW6yjktPsAOFZlxaSBIBpDpdlptlHrXfQueNPTCz8Da8Q59j9hAAL1GL8hnaXIZP1aLA7QmTGYZBZ5X34kI9jJm2J0BRIkO4nmK_POQFD8-s40IfTES8OBc3ucX_VaBYyW6vzqRcyIjk-b5bnye2g3bjueD2TI4xIwDG8XH_FLhS6Z5y1Rj-3OwE_jkuSQNqNiR3B0fkivnjxvH_kbqOfwVy5Fp4UrH4MGDKqj1VUPHKvlVyI3kWZFFvlbiaJd4c0RwywR-J0XRPiqJGTzXDUGl735LmYP46Yj-nNT5AGrBkcCUuyageuAXNOX9YmkqT47lQbdJv2NP-GG5wIbI_qVvRdAMggqaRlmxJ3MBeRjOSh8LUKj-b33d3OR7-e4FrkqD5To2Rq8biVjegCRZbfkiblCtsayXxdQIAhWeIZ6-SMwUCwlNhqIFCsAIvVBq57ySVy2)](https://editor.plantuml.com/uml/RL9DJy904BtlhvZqf8V6kmT2HOqQZOIMS10FotQW6yjktPsAOFZlxaSBIBpDpdlptlHrXfQueNPTCz8Da8Q59j9hAAL1GL8hnaXIZP1aLA7QmTGYZBZ5X34kI9jJm2J0BRIkO4nmK_POQFD8-s40IfTES8OBc3ucX_VaBYyW6vzqRcyIjk-b5bnye2g3bjueD2TI4xIwDG8XH_FLhS6Z5y1Rj-3OwE_jkuSQNqNiR3B0fkivnjxvH_kbqOfwVy5Fp4UrH4MGDKqj1VUPHKvlVyI3kWZFFvlbiaJd4c0RwywR-J0XRPiqJGTzXDUGl735LmYP46Yj-nNT5AGrBkcCUuyageuAXNOX9YmkqT47lQbdJv2NP-GG5wIbI_qVvRdAMggqaRlmxJ3MBeRjOSh8LUKj-b33d3OR7-e4FrkqD5To2Rq8biVjegCRZbfkiblCtsayXxdQIAhWeIZ6-SMwUCwlNhqIFCsAIvVBq57ySVy2)

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

[![](https://img.plantuml.biz/plantuml/svg/VLLDRzim3BthLn0-jGTZwBM7e6bt2RO1mxfYmBfWa6Kbrc9RhaGtJORyzr4VjjNMsI66nFSUIP6KScEH6-oRcjLoWu0QZDfM2AKoKg3IBMEei9QGBR6IxH4Uh8GxJX_TmgU-aAQLA6t661UeJKep6N0BFIqOVOJJP3za0RT6xmUq2Ek94ELtdrSU5xLYJDIwBo6Ref6vj-XS_6K0WXj2XJbqEnL4nji1MbtA0Scjtc1bcy2maG7m6E1r4Bhb04I1H-BQGoSMVY5kIDXxvI7tD7OmvNr8h9-Yka8yhBplNerktyYEZSsfEi-nMCT9_lFBlTSIuwmONuan4N-FOZmhBWilAejHLNBaHTgYZxVP299JokHt2FUh7RX3YcMHyF0S3oVUQQRGOGewevzL6Sz4cxbg4zxIq1xor-If0F44gyY3hv6tZaxzPYO58wtkZQ3PtxVHgr_D9S5xhBHHH-ukaSlavH269EdYCkN0lQ-Apy69ZmFhsn0r8GoPpDP9qR60TrqOTJwNNI05mfJFNP0kksuTBnzjan0dvYwgWNmnN5ou1jt9bWtRdA1UaRL2x2vgBNXTQOkNeuvy4YfVf61kwVWq855WoVyxsqM3jRraD1xdaCOX0QA1lORcO9_gIO2fTJGFRIOasykYqdeNl6Q1ieYlWSE5DAWsId2KODMsLQtQKWkUUcanOv57YlXAaAJR2NjrvPukNz6Onvl4VPV_Zot6Ji_KT7JkJnyKgPSFV_R46ccFbIffujV9uTdeFKLZtzcDR4ltp_0F)](https://editor.plantuml.com/uml/VLLDRzim3BthLn0-jGTZwBM7e6bt2RO1mxfYmBfWa6Kbrc9RhaGtJORyzr4VjjNMsI66nFSUIP6KScEH6-oRcjLoWu0QZDfM2AKoKg3IBMEei9QGBR6IxH4Uh8GxJX_TmgU-aAQLA6t661UeJKep6N0BFIqOVOJJP3za0RT6xmUq2Ek94ELtdrSU5xLYJDIwBo6Ref6vj-XS_6K0WXj2XJbqEnL4nji1MbtA0Scjtc1bcy2maG7m6E1r4Bhb04I1H-BQGoSMVY5kIDXxvI7tD7OmvNr8h9-Yka8yhBplNerktyYEZSsfEi-nMCT9_lFBlTSIuwmONuan4N-FOZmhBWilAejHLNBaHTgYZxVP299JokHt2FUh7RX3YcMHyF0S3oVUQQRGOGewevzL6Sz4cxbg4zxIq1xor-If0F44gyY3hv6tZaxzPYO58wtkZQ3PtxVHgr_D9S5xhBHHH-ukaSlavH269EdYCkN0lQ-Apy69ZmFhsn0r8GoPpDP9qR60TrqOTJwNNI05mfJFNP0kksuTBnzjan0dvYwgWNmnN5ou1jt9bWtRdA1UaRL2x2vgBNXTQOkNeuvy4YfVf61kwVWq855WoVyxsqM3jRraD1xdaCOX0QA1lORcO9_gIO2fTJGFRIOasykYqdeNl6Q1ieYlWSE5DAWsId2KODMsLQtQKWkUUcanOv57YlXAaAJR2NjrvPukNz6Onvl4VPV_Zot6Ji_KT7JkJnyKgPSFV_R46ccFbIffujV9uTdeFKLZtzcDR4ltp_0F)

# Learn More

Visit the official Athenz website: [www.athenz.io](http://www.athenz.io)  

## Learn how to use Athenz in practice

- [How to generate keys and certificates](CERTIFICATES.md)
 
- [CLI instruction](CLI.md)
 
- [How to generate keys and retrieve certificates (**Identity Provisioning**)](IDENTITYPROVISIONING.md)

- [Envoy Ambassador Instruction for Kubernetes](ENVOY.md)

