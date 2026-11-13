FROM public.ecr.aws/amazonlinux/amazonlinux:2023-minimal

# AWS publishes packages for both architectures used by KinD in this repository.
ARG RPM_ARCH=x86_64
ADD https://downloads.aws.com/aws-emulator/packages/aws-emulator/LTS/latest/aws-emulator-${RPM_ARCH}.rpm /tmp/aws-emulator.rpm
RUN rpm -i /tmp/aws-emulator.rpm && rm /tmp/aws-emulator.rpm \
    && mkdir -p /home/emulator/.aws/emulator \
    && chown -R 10001:10001 /home/emulator

USER 10001:10001
ENV HOME=/home/emulator
EXPOSE 9297
ENTRYPOINT ["aws-emulator", "--bind", "0.0.0.0", "--telemetry", "off"]
