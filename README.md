# ripcd

Rip CD with ripit and save id image with cdrdao. Without freedb.org.

# Usage

```
ripcd.zsh
```

# Environment variables

`RIPCD_OUTDIR` is an output directory for flac audio files.
Get with `xdg-user-dir MUSIC` by default.

`RIPCD_IMGDIR` is an output directory for cd image.
Default is `$(xdg-user-dir MUSIC)/rip`.

# Utils

## walkman_aac.zsh

```
walkman_aac.zsh source_dir dest_dir
```
