#------- build -------
FROM swiftlang/swift:nightly-centos8 as build

# set up the workspace
RUN mkdir /workspace
WORKDIR /workspace

# copy the source to the docker image
COPY . /workspace

RUN swift build -c release

#------- package -------
FROM centos:8
# copy executables
COPY --from=build /workspace/.build/release/Server /
# copy Swift's dynamic libraries dependencies
COPY --from=build /usr/lib/swift/linux/lib*so* /

# set the entry point (application name)
CMD ["./Server"]
