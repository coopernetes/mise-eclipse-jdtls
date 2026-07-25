# Eclipse JDT Language Server (jdtls) mise plugin

[`mise`](https://mise.jdx.dev/) plugin to handle manual installation of [`jdtls`](https://github.com/eclipse-jdtls/eclipse.jdt.ls) for distributions which may have a native package missing or the package is outdated.

>!NOTE
> This plugin only supports jdtls pre-built binaries for milestone and snapshot builds. There is no pre-compiled release binary. mise eclipse-jdtls compiles release verions using the system compiler.

## Usage

```shell
mise plugin install https://github.com/coopernetes/mise-eclipse-jdtls-plugin

mise install eclipse-jdtls@latest # Clone and compile the project from source.

mise install eclipse-jdtls@v1.60.0-milestone # Downloads pre-compiled binary from https://download.eclipse.org/jdtls/milestones/

mise install eclipse-jdtls@latest-snapshot # Downloads  jdt-language-server-latest.tar.gz pre-compiled binary from https://download.eclipse.org/jdtls/snapshots/

mise use eclipse-jdtls@latest

jdtls --version
```

## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md).

## License

MIT

