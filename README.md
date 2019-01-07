# Ethereum Security Toolbox

This repository contains scripts to create a Docker container preinstalled and preconfigured with all of Trail of Bits’ Ethereum security tools, including:

* [Echidna](https://github.com/trailofbits/echidna) property-based fuzz tester
* [Etheno](https://github.com/trailofbits/etheno) integration tool and differential tester
* [Manticore](https://github.com/trailofbits/manticore) symbolic analyzer and formal contract verifier
* [Slither](https://github.com/trailofbits/slither) static analysis tool
* [Rattle](https://github.com/trailofbits/rattle) EVM lifter
* [Not So Smart Contracts](https://github.com/trailofbits/not-so-smart-contracts) repository

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

As many versions of Solidity as possible are installed. They can be individually executed as `solc-v0.4.18` or `solc-v0.5.2`. By default, `solc` (with no version suffix) corresponds to the latest release. This can be changed using the `solc-select` script:
```
$ solc --version
solc, the solidity compiler commandline interface
Version: 0.5.2+commit.1df8f40c.Linux.g++
$ solc-select 0.4.24
$ solc --version
solc, the solidity compiler commandline interface
Version: 0.4.24+commit.e67f0147.Linux.g++
```

## Getting Help

Feel free to stop by our [Slack channel](https://empirehacking.slack.com/) for help on using or extending this toolbox.

## License

The Ethereum Security Toolbox is licensed and distributed under the [AGPLv3](LICENSE) license. [Contact us](mailto:opensource@trailofbits.com) if you’re looking for an exception to the terms.
