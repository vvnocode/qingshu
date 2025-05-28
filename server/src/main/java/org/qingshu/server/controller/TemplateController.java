package org.qingshu.server.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.qingshu.server.dal.dataobject.TemplateDO;
import org.qingshu.server.framework.common.pojo.CommonResult;
import org.qingshu.server.service.TemplateService;

import jakarta.validation.Valid;
import java.util.List;

/**
 * 情书模板控制器
 *
 * @author vvnocode
 */
@Tag(name = "情书模板", description = "情书模板相关接口")
@RestController
@RequestMapping("/templates")
@Slf4j
public class TemplateController {

    @Resource
    private TemplateService templateService;

    @PostMapping("/create")
    @Operation(summary = "创建模板", description = "创建新的情书模板")
    public CommonResult<Long> createTemplate(@Valid @RequestBody TemplateDO templateDO) {
        Long templateId = templateService.createTemplate(templateDO);
        return CommonResult.success(templateId);
    }

    @PutMapping("/update")
    @Operation(summary = "更新模板", description = "更新情书模板信息")
    public CommonResult<Boolean> updateTemplate(@Valid @RequestBody TemplateDO templateDO) {
        templateService.updateTemplate(templateDO);
        return CommonResult.success(true);
    }

    @DeleteMapping("/delete/{id}")
    @Operation(summary = "删除模板", description = "根据ID删除情书模板")
    public CommonResult<Boolean> deleteTemplate(@Parameter(description = "模板ID") @PathVariable("id") Long id) {
        templateService.deleteTemplate(id);
        return CommonResult.success(true);
    }

    @GetMapping("/get/{id}")
    @Operation(summary = "获取模板", description = "根据ID获取情书模板详情")
    public CommonResult<TemplateDO> getTemplate(@Parameter(description = "模板ID") @PathVariable("id") Long id) {
        TemplateDO template = templateService.getTemplate(id);
        return CommonResult.success(template);
    }

    @GetMapping("/list-by-category")
    @Operation(summary = "根据分类获取模板列表", description = "根据分类ID获取情书模板列表")
    public CommonResult<List<TemplateDO>> getTemplatesByCategoryId(
            @Parameter(description = "分类ID") @RequestParam("categoryId") Long categoryId) {
        List<TemplateDO> templates = templateService.getTemplatesByCategoryId(categoryId);
        return CommonResult.success(templates);
    }

    @GetMapping("/list-by-style")
    @Operation(summary = "根据风格获取模板列表", description = "根据风格获取情书模板列表")
    public CommonResult<List<TemplateDO>> getTemplatesByStyle(
            @Parameter(description = "风格") @RequestParam("style") String style) {
        List<TemplateDO> templates = templateService.getTemplatesByStyle(style);
        return CommonResult.success(templates);
    }

    @GetMapping("/hot")
    @Operation(summary = "获取热门模板", description = "获取热门情书模板列表")
    public CommonResult<List<TemplateDO>> getHotTemplates(
            @Parameter(description = "限制数量，默认10") @RequestParam(value = "limit", defaultValue = "10") Integer limit) {
        List<TemplateDO> templates = templateService.getHotTemplates(limit);
        return CommonResult.success(templates);
    }

    @GetMapping("/page")
    @Operation(summary = "分页查询模板", description = "分页查询情书模板，支持条件筛选")
    public CommonResult<IPage<TemplateDO>> getTemplatePage(
            @Parameter(description = "页码，从1开始") @RequestParam(value = "pageNo", defaultValue = "1") Integer pageNo,
            @Parameter(description = "页面大小") @RequestParam(value = "pageSize", defaultValue = "10") Integer pageSize,
            @Parameter(description = "分类ID") @RequestParam(value = "categoryId", required = false) Long categoryId,
            @Parameter(description = "风格") @RequestParam(value = "style", required = false) String style,
            @Parameter(description = "关键词") @RequestParam(value = "keyword", required = false) String keyword) {

        Page<TemplateDO> page = new Page<>(pageNo, pageSize);
        IPage<TemplateDO> result = templateService.getTemplatePage(page, categoryId, style, keyword);
        return CommonResult.success(result);
    }

    @PostMapping("/use/{id}")
    @Operation(summary = "使用模板", description = "记录模板使用次数")
    public CommonResult<Boolean> useTemplate(@Parameter(description = "模板ID") @PathVariable("id") Long id) {
        templateService.incrementUseCount(id);
        return CommonResult.success(true);
    }

}