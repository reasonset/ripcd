# ripcd

Rip CD with ripit and save id image with cdrdao. Without freedb.org.

# Require

* Zsh
* ffmpeg(1)
* fdkaac(1)
* ripit
* cdrdao
* flac(1)

# Usage

```
ripcd.zsh
```

# Config file

`${XDG_CONFIG_HOME:-$HOME/.config}/reasonset/ripcd.zsh` is a config file.

Define paramaters thus:

|Paramater|detail|
|-------|--------------------------|
|`RIPCD_OUTDIR`|Output directory for flac audio files. Get with `xdg-user-dir MUSIC` by default.|
|`RIPCD_IMGDIR`|Output directory for cd image. Default is `$(xdg-user-dir MUSIC)/rip`.|

# Utils

## walkman_aac.zsh

```
walkman_aac.zsh source_dir dest_dir
```

Convert source files to m4a with libfdk_aac, copy and fix filenames in m3u, and copy cover.jpg and replicate $albumname.jpg.

## walkman_aac.rb

```
walkman_aac.rb source_dir dest_dir
```

Convert source files to m4a with libfdk_aac, copy and fix filenames in m3u, and copy cover.jpg and replicate $albumname.jpg, Ruby version.

## walkman_setcovername.zsh

```
walkman_aac.rb walkman_dir
```

replicate cover.jpg to $albumname.jpg.
