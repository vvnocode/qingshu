+++
date = '2026-01-09T11:38:00+08:00'
draft = false
title = '使用GitHub Actions自动构建程序并发布到Release'
tags = ['GitHub Actions', 'Python', 'Release']
+++
## 前言

简单记录下使用使用GitHub Actions自动构建程序并发布到Release。摸索了好一阵，坑还比较多。

## 配置

配置主要分为构建和上传。这里使用python作为示例，为了能在其他语言复用这个模板，这里尽量配置得通用一点。

构建部分参考[Building and testing Python](https://docs.github.com/en/actions/use-cases-and-examples/building-and-testing/building-and-testing-python)。上传部分参考了多个开源项目，并且实践修改而来。

### 配置案例

创建配置文件`.github/workflows/python-package.yml`
```yaml
name: Python package

on:
  push:
    tags: [ '**' ]

jobs:
  Linux-build-amd64:
    name: Build Linux Amd64
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          # 必须加''
          python-version: '3.10'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install wheel pyinstaller
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

      - name: Pyinstaller
        run: |
          pyinstaller --onefile --add-data "conf.yaml.default:." --add-data "templates:templates" --name vpspeek app.py

      - name: Verify generated file
        run: |
          ls -l dist/

      - name: Upload Linux File
        uses: actions/upload-artifact@v3
        with:
          path: dist/vpspeek

  Create-release:
    permissions: write-all
    runs-on: ubuntu-latest
    needs: [ Linux-build-amd64 ]
    steps:
      - name: Download Linux File
        uses: actions/download-artifact@v3
        with:
          path: dist/

      - name: Move downloaded file
        run: |
          mv dist/artifact/* dist/

      - name: Verify file after move
        run: |
          ls dist/

      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.MY_GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false

      - name: Upload Release Asset
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.MY_GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: dist/vpspeek
          asset_name: vpspeek
          asset_content_type: application/octet-stream
```

### 配置说明

- `on.push.tags: [ '**' ]`每次打tag的时候都自动构建。
- jobs 分为 Linux-build-amd64 和  Create-release ，方便后面对 Windows 或者其他版本系统进行扩展。
- actions/setup-python@v5 的 python-version: '3.10' 必须使用''。如填3.10会被识别成3.1。
- `actions/download-artifact@v3` 下载步骤，会在下载的目录中为每个 artifact 创建一个子目录，默认情况下这个子目录的名称会是 artifact 名称（即 `artifact`）。这样就导致了期望文件 `vpspeek` 出现在 `dist/` 目录下，实际上它在 `dist/artifact/` 目录中。
	![EasyImage](static/images/2026/01/4c2a9dc43e4efa751c750c9fca73dc4f_MD5.jpg)
	解决办法就是把文件mv到dist或者直接使用artifact下的文件。
- GitHub不允许配置GITHUB_开头的secrets，MY_GITHUB_TOKEN。