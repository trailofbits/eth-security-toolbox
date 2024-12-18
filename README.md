# Ethereum Security Toolbox

This repository contains scripts to create a Docker container preinstalled and
preconfigured with all of Trail of Bits’ Ethereum security tools, including:

* [Echidna](https://github.com/crytic/echidna) property-based fuzz tester
* [Medusa](https://github.com/crytic/medusa) fuzz tester based on go-ethereum
* [Slither](https://github.com/crytic/slither) static analysis tool
* [solc-select](https://github.com/crytic/solc-select) to quickly switch between Solidity compiler versions
* [Building secure contracts](https://github.com/crytic/building-secure-contracts) repository

Other useful tools developed by third-parties are also included:

* [Foundry](https://github.com/foundry-rs/foundry), a toolkit for Ethereum app development
* [Vyper](https://github.com/vyperlang/vyper), a Pythonic Smart Contract language for the EVM
* [n](https://github.com/tj/n), a Node version manager
* npm and Yarn
* Python

## Quickstart

Use our prebuilt Docker container to quickly install and run the toolkit:

```shell
docker pull ghcr.io/trailofbits/eth-security-toolbox:nightly
docker run -it ghcr.io/trailofbits/eth-security-toolbox:nightly
```

Alternatively, build the image from scratch:

```shell
git clone https://github.com/trailofbits/eth-security-toolbox.git
cd eth-security-toolbox
docker build -t eth-security-toolbox .
```

## Usage

Simply start an instance of the Docker container:

```shell
docker run -it ghcr.io/trailofbits/eth-security-toolbox:nightly
```

Several Solidity versions are preinstalled via `solc-select`. By default, `solc`
corresponds to the latest release. This can be changed using the `solc-select`
tool:

```shell
$ solc --version
solc, the solidity compiler commandline interface
Version: 0.8.22+commit.4fc1097e.Linux.g++
$ solc-select use 0.4.26
$ solc --version
solc, the solidity compiler commandline interface
Version: 0.4.26+commit.4563c3fc.Linux.g++
```

You can also view the installed versions and install new ones:

```shell
$ solc-select versions
0.8.22 (current, set by /home/ethsec/.solc-select/global-version)
0.7.6
0.6.12
0.5.17
0.4.26
ethsec@f95fb29a709d:~$ solc-select install 0.8.0
Installing solc '0.8.0'...
Version '0.8.0' installed.
ethsec@f95fb29a709d:~$ solc-select use 0.8.0
Switched global version to 0.8.0
$ solc --version
solc, the solidity compiler commandline interface
Version: 0.8.0+commit.c7dfd78e.Linux.g++
```

The toolbox comes preinstalled with a LTS version of Node, and
[n](https://github.com/tj/n), the Node version manager. You can install other
versions of Node if needed by using `n`. Refer to their website for further
instructions.

```shell
$ sudo n 14
  installing : node-v14.21.3
       mkdir : /usr/local/n/versions/node/14.21.3
       fetch : https://nodejs.org/dist/v14.21.3/node-v14.21.3-linux-arm64.tar.gz
     copying : node/14.21.3
   installed : v14.21.3 (with npm 6.14.18)
$ node --version
v14.21.3
```

## Usage in CI

A variant of the image is published on GitHub Container Registry as
[`ghcr.io/trailofbits/eth-security-toolbox/ci`](https://github.com/trailofbits/eth-security-toolbox/pkgs/container/eth-security-toolbox%2Fci).
This variant is meant to be slightly lighter, and better suited for its use in
CI contexts such as [GitHub workflow jobs](https://docs.github.com/en/actions/writing-workflows/choosing-where-your-workflow-runs/running-jobs-in-a-container):


```yaml
# workflow triggers, ...

jobs:
  tests:
    runs-on: ubuntu-latest
    container: ghcr.io/trailofbits/eth-security-toolbox/ci:nightly
    steps:
      # other steps ...
      - run: medusa fuzz # or any tool from the image
```

The main differences are:
 * The container does not have a dedicated non-root user. All tools are
   installed under the root user.
 * Most autocompletions are not installed.
 * No solc binaries are preinstalled. You may continue to use `solc-select` to
   install any binaries you may need.
 * pyevmasm and the building secure contracts repository are not included.

## Container image labels

Both `eth-security-toolbox` and `eth-security-toolbox/ci` use the following
label convention:

| Label              | Description
|--------------------|--------------------------------------------------------
| `nightly-YYYYMMDD` | Image built from the code in `master` on day YYYY-MM-DD
| `nightly`          | Alias for the latest `nightly-YYYYMMDD` container image
| `testing-BRANCH`   | Image built when the tip of `BRANCH` was last updated
| `edge`             | Alias for `testing-master`
| `TAG`              | Image built when `TAG` was tagged
| `latest`           | Alias for the latest `TAG` container image

To keep tooling in CI predictable, we recommend picking a `nightly-YYYYMMDD`
image and pinning it by hash on your workflow file. Then, establish a process
to review the changes and update the container reference on a regular cadence,
so that you can continue to benefit from tool improvements. The following
snippet shows the syntax used to pin the image on a GitHub Actions workflow;
the hashes may be obtained from the [container registry page](https://github.com/orgs/trailofbits/packages?repo_name=eth-security-toolbox).

```yaml
container: ghcr.io/trailofbits/eth-security-toolbox/ci:nightly-YYYYMMDD@sha256:HASH_GOES_HERE
```

## Getting Help

Feel free to stop by our [Slack channel](https://slack.empirehacking.nyc/) for
help on using or extending this toolbox.

## License

The Ethereum Security Toolbox is licensed and distributed under the
[AGPLv3](LICENSE) license. [Contact us](mailto:opensource@trailofbits.com) if
you’re looking for an exception to the terms.
