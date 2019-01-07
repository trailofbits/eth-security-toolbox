# Ethereum Security Toolbox

This repository contains scripts to create a Docker container preinstalled and preconfigured with all of Trail of Bits’ Ethereum security tools, including:

* [Echidna](https://github.com/trailofbits/echidna) property-based fuzz tester
* [Etheno](https://github.com/trailofbits/etheno) integration tool and differential tester
* [Manticore](https://github.com/trailofbits/manticore) symbolic analyzer and formal contract verifier
* [Slither](https://github.com/trailofbits/slither) static analysis tool
* [Rattle](https://github.com/trailofbits/rattle) EVM lifter
* [Not So Smart Contracts](https://github.com/trailofbits/not-so-smart-contracts) repository

Note that all of the tools _except_ for Echidna are the latest possible release. Echidna is currently taken from its `dev-no-hedgehog` branch, which is required for Etheno. Once this branch is merged into Echidna master, this will no longer be the case.

## Quickstart

Use our prebuilt Docker container to quickly install and run the toolkit:

```
docker pull trailofbits/eth-security-toolbox
docker run -it trailofbits/eth-security-toolbox
```

Alternatively, build the image from scratch:

```
$ git clone https://github.com/trailofbits/eth-security-toolbox.git
$ cd eth-security-toolbox
$ docker build -t eth-security-toolbox .
```

## Usage

Simply start an instance of the Docker container:
```
docker run -it eth-security-toolbox
```

## Getting Help

Feel free to stop by our [Slack channel](https://empirehacking.slack.com/) for help on using or extending this toolbox.

## License

The Ethereum Security Toolbox is licensed and distributed under the [AGPLv3](LICENSE) license. [Contact us](mailto:opensource@trailofbits.com) if you’re looking for an exception to the terms.
