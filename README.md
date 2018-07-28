# vim-dn-markdown #

An auxiliary filetype plugin for the markdown language.

Previously the plugin author used a personal plugin to provide markdown-
related functionality. That plugin was retired when the plugin author switched
to the `vim-pandoc` plugin and [panzer
framework](https://github.com/msprev/panzer) for markdown support. This plugin
is intended to address any gaps in markdown support provided by those tools.

## Dependencies ##

Pandoc is used to generate output. It is not provided by this ftplugin. This
ftplugin depends on the `vim-pandoc` plugin and assumes
[panzer](https://github.com/msprev/panzer) is installed and configured.

This plugin is designed for use with pandoc version 2.0. At the time of writing
this is the development branch of pandoc, while the production version is 1.19.
As the change in major version number suggests, the interfaces of these two
versions of pandoc are incompatible. Hence, this plugin will not work with the
current production version of pandoc. There are two known incompatibilities
between these versions that affect this plugin:

| Feature    | Version 1.9      | Version 2.0                       |
|:-----------|:-----------------|:----------------------------------|
|smart       |`--smart` (option)|`--from=markdown+smart` (extension)|
|latex engine|`--latex-engine`  |`--pdf-engine`                     |

This plugin also depends on the
[vim-dn-utils](https://github.com/dnebauer/vim-dn-utils) plugin.

## Features ##

A default [panzer](https://github.com/msprev/panzer)- and pandoc-compatible
yaml-style metadata block can be added to a markdown file. An existing
pandoc-compatible metadata block can be processed to be
[panzer](https://github.com/msprev/panzer)-compatible as well.

A helper function, mapping and command are provided to assist with adding
figures. They assume the images are defined using reference links with optional
attributes, and that all reference links are added to the end of the document
prefixed with three spaces.

This plugin does not assist with generation of output, but does provide a
mapping, command and function for deleting output files and temporary output
directories. Read the help file carefully before using this feature as it is
potentially unsafe. By default, when buffers are deleted or vim exits, the user
has an opportunity to delete output files/directories. This feature can be
disabled.

## License ##

This plugin is distributed under the GNU GPL version 3.
