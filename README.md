# vim-dn-markdown #

A vim markdown ftplugin providing some utilities.

## Convert header to use panzer ##

Alters a yaml metadata block at the top of a document to use panzer.

Specifically, it preserves initial 'title', 'author' and 'date' fields,
removes all other content, and inserts the following panzer-specific field
which references custom styles:

```yaml
style:  # Latex@pt (@=8-12,14,17,20), PaginateSections
  - Standard
  - Latex12pt
```
