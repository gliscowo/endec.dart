## endec

endec is a format-agnostic serialization framework inspired by Rust's [serde](https://serde.rs) library and the Codec API from Mojang's [DataFixerUpper](https://github.com/mojang/datafixerupper).

This repository contains the in-progress reference implementation, written in [Dart](https://dart.dev). For a more-complete implementation without guarantees, see this repository's [sister project](https://github.com/wisp-forest/endec) on the Wisp Forest organization (written in Java).

### Repository Structure
This repository actually contains 7 separate dart packages. The root directory contains the core `endec` package which defines the API and contains some base implementations. The nested packages are as follows:
- `endec_tests`: Test suites for all other packages
- `endec_builder`: A build system builder for automatically generating struct endecs
- `endec_binary`: An (as of currently) unspecified binary format, good for networking
- `endec_edm`: The **e**ndec **d**ata **m**odel types and format implementation
- `endec_json`: Support for the JSON format
- `endec_nbt`: An implementation of Minecraft's **N**amed **B**inary **T**ag format, with binary and string encoding

### Documentation

For the time being, documentation can be found in the owo section of the [Wisp Forest docs](https://docs.wispforest.io/owo/endec). The linked document adequately explains the basics but is out-of-date and does not agree with this reference implementation in a number of places - it will be updated to match in the future

### Acknowledgements

The excellent serde documentation and [enjarai's](https://enjarai.dev) Codec guide [on the Fabric Docs](https://docs.fabricmc.net/develop/codecs) have been invaluable during development. Further, [Blodhgarm](https://github.com/dragon-seeker) is responsible for developing significant parts of the Java implementation