# Story Factory

这个目录用于把“互动爽文系统架构”落成可批量生成、可编译、可导入 App 的内容工厂。

## Directory Layout

- `SKILL.md`
  生成规则和硬约束
- `templates/story_package.template.json`
  统一物料模板
- `scripts/compile_story_package.py`
  校验并编译物料
- `projects/<book_id>/story_package.json`
  每本书的源物料

## What Goes In

每本书的源物料必须至少包含：

- `book`
- `reader_desire_map`
- `story_bible`
- `route_graph`
- `walkthrough`
- `chapters`

## Compile

```bash
python3 story-factory/scripts/compile_story_package.py \
  story-factory/projects/<book_id>/story_package.json \
  --resources-dir LifeScript-iOS/Sources/LifeScript/Resources \
  --output-dir story-factory/projects/<book_id>/build
```

## Compile Outputs

脚本会生成：

- `book_<book_id>.json`
- `chapters_<book_id>.json`
- `walkthrough_<book_id>.json`
- `qa_report.json`

前 3 个文件会被写入 App 的资源目录，最后一个会写入项目的 `build` 目录，方便审稿与自动化检查。
