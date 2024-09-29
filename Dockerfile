FROM ubuntu:22.04 AS stage

WORKDIR /workspace

RUN apt update

RUN apt install apt-transport-https curl gnupg openjdk-8-jdk -y
RUN curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor >bazel-archive-keyring.gpg
RUN mv bazel-archive-keyring.gpg /usr/share/keyrings
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list

RUN apt update

RUN apt install -y bazel

WORKDIR  /code

COPY bin .

RUN bazel fetch //src/main:BazelApp

RUN bazel build //src/main:BazelApp

FROM ubuntu:22.04

WORKDIR /workspace

RUN apt update

RUN apt install -y openjdk-17-jdk

WORKDIR /code

COPY bin .

COPY --from=stage /code/bazel-bin/src/main .

RUN echo "Main-Class: example.Main" > manifest.mf

RUN javac -cp . $(find src -type f -name "*.java")

RUN cp -R src/main/java/* .

RUN jar cfm Main.jar manifest.mf example

RUN jlink --add-modules $(jdeps --list-reduced-deps Main.jar) --output /code/jre

CMD ["/code/jre/bin/java", "-jar", "Main.jar"]
