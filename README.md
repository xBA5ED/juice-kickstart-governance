# juice-kickstart-governance (WIP)
A helper to launch a (or reconfigure an existing) project on Juicebox preconfigured to use on-chain governance.

## Motivation
On-chain governance is hard to configure for regular users and may cause irreverisable damage to a project if configured incorrectly.


## Install Foundry
To get set up:

1. Install [Foundry](https://github.com/gakonst/foundry).

```bash
curl -L https://foundry.paradigm.xyz | sh
```

2. Install external lib(s)

```bash
git submodule update --init
```

then run

```bash
forge update
```

If git modules are failing to clone, not installing, etc (ie overall submodule misbehaving), use `git submodule update --init --recursive --force`

3. Run tests:

```bash
forge test
```

4. Update Foundry periodically:

```bash
foundryup
```