#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Obsidian 笔记迁移脚本
用法: 
python3 scripts/migrate_obsidian.py --config scripts/migrate_config.yaml

@author vv 2026/01/09
"""

import re
import shutil
import argparse
from pathlib import Path

import yaml


def load_config(config_path: str) -> dict:
    """从 YAML 配置文件加载配置"""
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def update_image_paths(content: str, old_prefix: str, new_prefix: str) -> str:
    """更新 Markdown 内容中的图片路径"""
    # 替换标准 Markdown 图片格式 ![alt](path)
    def replace_path(match):
        path = match.group(1)
        if old_prefix in path:
            return match.group(0).replace(path, path.replace(old_prefix, new_prefix))
        return match.group(0)
    
    content = re.sub(r'!\[.*?\]\((.*?)\)', replace_path, content)
    # 替换 Obsidian 格式 ![[path]] 为标准格式
    content = re.sub(r'!\[\[(.*?)\]\]', lambda m: f'![]({m.group(1).replace(old_prefix, new_prefix)})', content)
    return content


def transfer_files(src_dir: Path, dest_dir: Path, patterns: list, copy_mode: bool = False) -> int:
    """移动或复制文件，返回文件数量"""
    count = 0
    dest_dir.mkdir(parents=True, exist_ok=True)
    operation = shutil.copy2 if copy_mode else shutil.move
    
    for pattern in patterns:
        for file in src_dir.rglob(pattern):
            if file.is_file():
                rel_path = file.relative_to(src_dir)
                dest_file = dest_dir / rel_path
                dest_file.parent.mkdir(parents=True, exist_ok=True)
                operation(str(file), str(dest_file))
                print(f"  {'复制' if copy_mode else '移动'}: {file.name}")
                count += 1
    return count


def process_markdown_files(md_dir: Path, old_prefix: str, new_prefix: str) -> int:
    """更新目录中所有 MD 文件的图片路径"""
    count = 0
    for md_file in md_dir.rglob("*.md"):
        content = md_file.read_text(encoding='utf-8')
        if old_prefix in content:
            md_file.write_text(update_image_paths(content, old_prefix, new_prefix), encoding='utf-8')
            print(f"  更新: {md_file.name}")
            count += 1
    return count


def main():
    parser = argparse.ArgumentParser(description='Obsidian 笔记迁移脚本')
    parser.add_argument('--config', '-c', type=str, required=True, help='YAML 配置文件路径')
    parser.add_argument('--dry-run', action='store_true', help='预览模式')
    args = parser.parse_args()
    
    # 加载配置
    config_path = Path(args.config).expanduser()
    if not config_path.exists():
        print(f"错误：配置文件不存在: {config_path}")
        return
    
    config = load_config(str(config_path))
    
    md_src = Path(config['source']['md_dir']).expanduser()
    md_dest = Path(config['destination']['md_dir']).expanduser()
    img_src = Path(config['source']['img_dir']).expanduser()
    img_dest = Path(config['destination']['img_dir']).expanduser()
    old_prefix = config['path_replace']['old_prefix']
    new_prefix = config['path_replace']['new_prefix']
    copy_mode = config.get('options', {}).get('copy_mode', False)
    
    print(f"\n{'='*50}")
    print(f"MD:  {md_src} -> {md_dest}")
    print(f"IMG: {img_src} -> {img_dest}")
    print(f"路径: {old_prefix} -> {new_prefix}")
    print(f"模式: {'复制' if copy_mode else '移动'}")
    print(f"{'='*50}\n")
    
    if args.dry_run:
        print("[预览模式] 不执行实际操作")
        return
    
    # 1. 移动/复制 MD 文件
    if md_src.exists():
        print("[1/3] 处理 Markdown 文件...")
        n = transfer_files(md_src, md_dest, ["*.md"], copy_mode)
        print(f"  完成: {n} 个文件\n")
    
    # 2. 移动/复制图片
    if img_src.exists():
        print("[2/3] 处理图片文件...")
        n = transfer_files(img_src, img_dest, ["*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp"], copy_mode)
        print(f"  完成: {n} 个图片\n")
    
    # 3. 更新路径
    if md_dest.exists():
        print("[3/3] 更新图片路径...")
        n = process_markdown_files(md_dest, old_prefix, new_prefix)
        print(f"  完成: {n} 个文件\n")
    
    print("迁移完成！")


if __name__ == '__main__':
    main()
