package org.qingshu.server.service.impl;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.qingshu.server.dal.dataobject.TemplateDO;
import org.qingshu.server.dal.mysql.TemplateMapper;
import org.qingshu.server.service.TemplateService;

import java.util.List;

/**
 * 情书模板 Service 实现类
 *
 * @author vvnocode
 */
@Service
@Slf4j
public class TemplateServiceImpl implements TemplateService {

    @Resource
    private TemplateMapper templateMapper;

    @Override
    public Long createTemplate(TemplateDO templateDO) {
        // 校验模板名称唯一性
        validateTemplateNameUnique(templateDO.getName(), null);
        
        // 插入模板
        templateMapper.insert(templateDO);
        return templateDO.getId();
    }

    @Override
    public void updateTemplate(TemplateDO templateDO) {
        // 校验模板存在
        validateTemplateExists(templateDO.getId());
        
        // 校验模板名称唯一性
        validateTemplateNameUnique(templateDO.getName(), templateDO.getId());
        
        // 更新模板
        templateMapper.updateById(templateDO);
    }

    @Override
    public void deleteTemplate(Long id) {
        // 校验模板存在
        validateTemplateExists(id);
        
        // 删除模板
        templateMapper.deleteById(id);
    }

    @Override
    public TemplateDO getTemplate(Long id) {
        return templateMapper.selectById(id);
    }

    @Override
    public List<TemplateDO> getTemplatesByCategoryId(Long categoryId) {
        return templateMapper.selectByCategoryId(categoryId);
    }

    @Override
    public List<TemplateDO> getTemplatesByStyle(String style) {
        return templateMapper.selectByStyle(style);
    }

    @Override
    public List<TemplateDO> getHotTemplates(int limit) {
        return templateMapper.selectHotTemplates(limit);
    }

    @Override
    public IPage<TemplateDO> getTemplatePage(Page<TemplateDO> page, Long categoryId, String style, String keyword) {
        return templateMapper.selectPage(page, categoryId, style, keyword);
    }

    @Override
    public void incrementUseCount(Long id) {
        TemplateDO template = getTemplate(id);
        if (template != null) {
            template.setUseCount(template.getUseCount() + 1);
            templateMapper.updateById(template);
        }
    }

    @Override
    public void validateTemplateExists(Long id) {
        if (getTemplate(id) == null) {
            throw new IllegalArgumentException("模板不存在");
        }
    }

    /**
     * 校验模板名称的唯一性
     *
     * @param name 模板名称
     * @param id   模板ID（更新时传入）
     */
    private void validateTemplateNameUnique(String name, Long id) {
        // 这里简化处理，实际项目中可以添加根据名称查询的方法
        // TemplateDO template = templateMapper.selectByName(name);
        // 为了简化，暂时跳过唯一性校验
    }

} 