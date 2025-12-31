"""
Compiler: Complete formatting pipeline.

Pipeline:
1. Parse input (Markdown/plain text) -> DocumentAST
2. Generate/load StyleSpec
3. Generate reference.docx template
4. Render AST + template -> output.docx
5. Validate output
6. Auto-fix if needed
7. Return final docx bytes + report
"""
from __future__ import annotations

import io
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Callable, List, Optional

from ..models.ast import DocumentAST
from ..models.stylespec import StyleSpec
from ..models.validation import ValidationReport, ValidationSummary

from .ast_generator import parse_markdown_to_ast, parse_plaintext_heuristic
from .fixer import fix_docx
from .renderer import RenderOptions, render_docx
from .spec_generator import build_generic_spec, builtin_specs
from .template_generator import generate_reference_docx, patch_reference_docx
from .validator import validate_docx


class InputFormat(str, Enum):
    MARKDOWN = "markdown"
    PLAINTEXT = "plaintext"
    AUTO = "auto"


class CompilePhase(str, Enum):
    PARSE = "parse"
    SPEC = "spec"
    TEMPLATE = "template"
    RENDER = "render"
    VALIDATE = "validate"
    FIX = "fix"
    DONE = "done"


@dataclass
class CompileProgress:
    phase: CompilePhase
    progress: float  # 0.0 - 1.0
    message: str
    detail: Optional[str] = None


@dataclass
class CompileResult:
    success: bool
    docx_bytes: Optional[bytes] = None
    ast: Optional[DocumentAST] = None
    spec: Optional[StyleSpec] = None
    report: Optional[ValidationReport] = None
    error: Optional[str] = None
    warnings: List[str] = field(default_factory=list)


@dataclass
class CompileOptions:
    input_format: InputFormat = InputFormat.AUTO
    spec_name: Optional[str] = None
    custom_spec: Optional[StyleSpec] = None
    reference_docx_bytes: Optional[bytes] = None
    include_cover: bool = True
    include_toc: bool = True
    toc_title: str = "目 录"
    auto_fix: bool = True
    max_fix_iterations: int = 3


ProgressCallback = Callable[[CompileProgress], None]


def detect_input_format(text: str) -> InputFormat:
    """Detect if input is Markdown or plain text."""
    md_indicators = [
        text.strip().startswith("---"),
        "# " in text[:500],
        "## " in text[:500],
        "### " in text[:500],
        "```" in text,
        "![" in text,
        "| " in text and " |" in text,
    ]
    if sum(md_indicators) >= 2:
        return InputFormat.MARKDOWN
    return InputFormat.PLAINTEXT


def compile_document(
    text: str,
    options: Optional[CompileOptions] = None,
    progress_callback: Optional[ProgressCallback] = None,
) -> CompileResult:
    """
    Complete document compilation pipeline.

    Args:
        text: Input text (Markdown or plain text)
        options: Compilation options
        progress_callback: Optional callback for progress updates

    Returns:
        CompileResult with docx bytes and metadata
    """
    options = options or CompileOptions()
    warnings: List[str] = []

    print("\n" + "=" * 80, flush=True)
    print("[WORD-FORMATTER] 文档编译开始 (规则模式)", flush=True)
    print(f"[WORD-FORMATTER] 输入文本长度: {len(text)} 字符", flush=True)
    print(f"[WORD-FORMATTER] 规范名称: {options.spec_name or 'Default'}", flush=True)
    print(f"[WORD-FORMATTER] 包含封面: {options.include_cover}", flush=True)
    print(f"[WORD-FORMATTER] 包含目录: {options.include_toc}", flush=True)

    def notify(phase: CompilePhase, progress: float, msg: str, detail: str = None):
        print(f"[WORD-FORMATTER] [{phase.value}] {msg}" + (f" - {detail}" if detail else ""), flush=True)
        if progress_callback:
            progress_callback(CompileProgress(phase, progress, msg, detail))

    try:
        # Phase 1: Parse input
        notify(CompilePhase.PARSE, 0.0, "解析输入文本...")

        input_format = options.input_format
        if input_format == InputFormat.AUTO:
            input_format = detect_input_format(text)

        if input_format == InputFormat.MARKDOWN:
            ast = parse_markdown_to_ast(text)
        else:
            ast = parse_plaintext_heuristic(text)

        notify(CompilePhase.PARSE, 1.0, "文本解析完成", f"识别到 {len(ast.blocks)} 个内容块")

        # Phase 2: Load/generate spec
        notify(CompilePhase.SPEC, 0.0, "加载格式规范...")

        if options.custom_spec:
            spec = options.custom_spec
        elif options.spec_name and options.spec_name in builtin_specs():
            spec = builtin_specs()[options.spec_name]
        else:
            spec = build_generic_spec()

        notify(CompilePhase.SPEC, 1.0, "格式规范已加载", spec.meta.get("name", "Custom"))

        # Phase 3: Generate template
        notify(CompilePhase.TEMPLATE, 0.0, "生成模板文档...")

        if options.reference_docx_bytes:
            reference_bytes = patch_reference_docx(spec, options.reference_docx_bytes)
        else:
            reference_bytes = generate_reference_docx(spec)

        notify(CompilePhase.TEMPLATE, 1.0, "模板文档已生成")

        # Phase 4: Render document
        notify(CompilePhase.RENDER, 0.0, "渲染文档...")

        render_opts = RenderOptions(
            include_cover=options.include_cover,
            include_toc=options.include_toc,
            toc_title=options.toc_title,
        )
        docx_bytes = render_docx(ast, spec, reference_bytes, render_opts)

        notify(CompilePhase.RENDER, 1.0, "文档渲染完成")

        # Phase 5: Validate
        notify(CompilePhase.VALIDATE, 0.0, "验证文档...")

        report = validate_docx(docx_bytes, spec)

        notify(CompilePhase.VALIDATE, 1.0, "文档验证完成",
               f"错误: {report.summary.errors}, 警告: {report.summary.warnings}")

        # Phase 6: Auto-fix if needed
        if options.auto_fix and not report.summary.ok:
            notify(CompilePhase.FIX, 0.0, "自动修复问题...")

            for i in range(options.max_fix_iterations):
                docx_bytes = fix_docx(docx_bytes, report, spec)
                report = validate_docx(docx_bytes, spec)

                progress = (i + 1) / options.max_fix_iterations
                notify(CompilePhase.FIX, progress, f"修复迭代 {i + 1}/{options.max_fix_iterations}")

                if report.summary.ok:
                    break

            if not report.summary.ok:
                warnings.append(f"自动修复后仍有 {report.summary.errors} 个错误")

            notify(CompilePhase.FIX, 1.0, "修复完成")

        notify(CompilePhase.DONE, 1.0, "编译完成")

        return CompileResult(
            success=True,
            docx_bytes=docx_bytes,
            ast=ast,
            spec=spec,
            report=report,
            warnings=warnings,
        )

    except Exception as e:
        return CompileResult(
            success=False,
            error=str(e),
            warnings=warnings,
        )


async def compile_document_with_ai(
    text: str,
    ai_service: Any,
    options: Optional[CompileOptions] = None,
    progress_callback: Optional[ProgressCallback] = None,
) -> CompileResult:
    """
    Compile document with AI-assisted paragraph type identification.

    Args:
        text: Input text
        ai_service: AI service instance for paragraph identification
        options: Compilation options
        progress_callback: Optional progress callback

    Returns:
        CompileResult with docx bytes and metadata

    Note:
        AI 调用失败时会自动降级到规则识别（在 ai_identify_paragraph_types 内部处理）
    """
    from .ast_generator import ai_identify_paragraph_types, parse_plaintext_with_ai_types

    options = options or CompileOptions()
    warnings: List[str] = []

    print("\n" + "=" * 80, flush=True)
    print("[WORD-FORMATTER] 文档编译开始 (AI 智能模式)", flush=True)
    print(f"[WORD-FORMATTER] 输入文本长度: {len(text)} 字符", flush=True)
    print(f"[WORD-FORMATTER] 规范名称: {options.spec_name or 'Default'}", flush=True)
    print(f"[WORD-FORMATTER] 包含封面: {options.include_cover}", flush=True)
    print(f"[WORD-FORMATTER] 包含目录: {options.include_toc}", flush=True)

    def notify(phase: CompilePhase, progress: float, msg: str, detail: str = None):
        print(f"[WORD-FORMATTER] [{phase.value}] {msg}" + (f" - {detail}" if detail else ""), flush=True)
        if progress_callback:
            progress_callback(CompileProgress(phase, progress, msg, detail))

    try:
        notify(CompilePhase.PARSE, 0.0, "AI 分析文本结构...")

        input_format = options.input_format
        if input_format == InputFormat.AUTO:
            input_format = detect_input_format(text)
            print(f"[WORD-FORMATTER] 自动检测格式: {input_format.value}", flush=True)

        if input_format == InputFormat.MARKDOWN:
            ast = parse_markdown_to_ast(text)
            notify(CompilePhase.PARSE, 1.0, "Markdown 解析完成")
        else:
            paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
            print(f"[WORD-FORMATTER] 分割得到 {len(paragraphs)} 个段落", flush=True)
            notify(CompilePhase.PARSE, 0.3, "调用 AI 识别段落类型...")

            # ai_identify_paragraph_types 内部已有 fallback 机制
            # 如果 AI 调用失败，会自动降级到规则识别
            identified = await ai_identify_paragraph_types(paragraphs, ai_service)
            ast = parse_plaintext_with_ai_types(text, identified)
            notify(CompilePhase.PARSE, 1.0, "段落识别完成", f"识别到 {len(ast.blocks)} 个内容块")

        return await _compile_from_ast(ast, options, progress_callback, warnings)

    except Exception as e:
        # 如果整个流程失败，尝试降级到非 AI 编译
        import traceback
        print("=" * 80, flush=True)
        print(f"[WORD-FORMATTER] ⚠️ AI 编译流程异常: {e}", flush=True)
        print(f"[WORD-FORMATTER] 异常类型: {type(e).__name__}", flush=True)
        print(f"[WORD-FORMATTER] 堆栈跟踪:\n{traceback.format_exc()}", flush=True)
        print("[WORD-FORMATTER] 尝试降级到规则编译模式...", flush=True)
        print("=" * 80, flush=True)

        try:
            warnings.append(f"AI 编译失败，已降级到规则模式: {str(e)}")
            notify(CompilePhase.PARSE, 0.5, "降级到规则解析模式...")
            # compile_document 是同步函数，直接调用即可
            return compile_document(text, options, progress_callback)
        except Exception as fallback_error:
            print(f"[WORD-FORMATTER] ❌ 降级编译也失败: {fallback_error}", flush=True)
            return CompileResult(
                success=False,
                error=f"编译失败: {str(fallback_error)} (原始错误: {str(e)})",
                warnings=warnings,
            )


async def _compile_from_ast(
    ast: DocumentAST,
    options: CompileOptions,
    progress_callback: Optional[ProgressCallback],
    warnings: List[str],
) -> CompileResult:
    """Internal: compile from parsed AST."""

    def notify(phase: CompilePhase, progress: float, msg: str, detail: str = None):
        print(f"[WORD-FORMATTER] [{phase.value}] {msg}" + (f" - {detail}" if detail else ""), flush=True)
        if progress_callback:
            progress_callback(CompileProgress(phase, progress, msg, detail))

    try:
        notify(CompilePhase.SPEC, 0.0, "加载格式规范...")

        if options.custom_spec:
            spec = options.custom_spec
            spec_source = "自定义规范"
        elif options.spec_name and options.spec_name in builtin_specs():
            spec = builtin_specs()[options.spec_name]
            spec_source = f"内置规范: {options.spec_name}"
        else:
            spec = build_generic_spec()
            spec_source = "默认通用规范"

        print(f"[WORD-FORMATTER] 规范来源: {spec_source}", flush=True)
        notify(CompilePhase.SPEC, 1.0, "格式规范已加载", spec.meta.get("name", "Unknown"))

        notify(CompilePhase.TEMPLATE, 0.0, "生成模板文档...")

        if options.reference_docx_bytes:
            reference_bytes = patch_reference_docx(spec, options.reference_docx_bytes)
            print(f"[WORD-FORMATTER] 使用自定义参考模板，大小: {len(options.reference_docx_bytes)} 字节", flush=True)
        else:
            reference_bytes = generate_reference_docx(spec)
            print(f"[WORD-FORMATTER] 生成新模板，大小: {len(reference_bytes)} 字节", flush=True)

        notify(CompilePhase.TEMPLATE, 1.0, "模板文档已生成")

        notify(CompilePhase.RENDER, 0.0, "渲染文档...")
        print(f"[WORD-FORMATTER] 渲染选项: 封面={options.include_cover}, 目录={options.include_toc}, 目录标题='{options.toc_title}'", flush=True)

        render_opts = RenderOptions(
            include_cover=options.include_cover,
            include_toc=options.include_toc,
            toc_title=options.toc_title,
        )
        docx_bytes = render_docx(ast, spec, reference_bytes, render_opts)

        print(f"[WORD-FORMATTER] 渲染完成，文档大小: {len(docx_bytes)} 字节", flush=True)
        notify(CompilePhase.RENDER, 1.0, "文档渲染完成")

        notify(CompilePhase.VALIDATE, 0.0, "验证文档...")

        report = validate_docx(docx_bytes, spec)

        print(f"[WORD-FORMATTER] 验证结果: 错误={report.summary.errors}, 警告={report.summary.warnings}", flush=True)
        notify(CompilePhase.VALIDATE, 1.0, "验证完成", f"错误: {report.summary.errors}, 警告: {report.summary.warnings}")

        if options.auto_fix and not report.summary.ok:
            notify(CompilePhase.FIX, 0.0, "自动修复...")
            print(f"[WORD-FORMATTER] 开始自动修复，最大迭代次数: {options.max_fix_iterations}", flush=True)

            for i in range(options.max_fix_iterations):
                docx_bytes = fix_docx(docx_bytes, report, spec)
                report = validate_docx(docx_bytes, spec)
                print(f"[WORD-FORMATTER] 修复迭代 {i + 1}: 错误={report.summary.errors}, 警告={report.summary.warnings}", flush=True)
                if report.summary.ok:
                    print(f"[WORD-FORMATTER] 修复成功，共迭代 {i + 1} 次", flush=True)
                    break

            if not report.summary.ok:
                print(f"[WORD-FORMATTER] ⚠️ 达到最大迭代次数后仍有 {report.summary.errors} 个错误", flush=True)

            notify(CompilePhase.FIX, 1.0, "修复完成")

        print(f"[WORD-FORMATTER] 最终文档大小: {len(docx_bytes)} 字节", flush=True)
        print("=" * 80 + "\n", flush=True)
        notify(CompilePhase.DONE, 1.0, "编译完成")

        return CompileResult(
            success=True,
            docx_bytes=docx_bytes,
            ast=ast,
            spec=spec,
            report=report,
            warnings=warnings,
        )

    except Exception as e:
        import traceback
        print("=" * 80, flush=True)
        print(f"[WORD-FORMATTER] ❌ AST 编译失败: {e}", flush=True)
        print(f"[WORD-FORMATTER] 异常类型: {type(e).__name__}", flush=True)
        print(f"[WORD-FORMATTER] 堆栈跟踪:\n{traceback.format_exc()}", flush=True)
        print("=" * 80 + "\n", flush=True)
        return CompileResult(
            success=False,
            error=str(e),
            warnings=warnings,
        )
