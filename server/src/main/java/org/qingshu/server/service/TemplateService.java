package org.qingshu.server.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.qingshu.server.dal.dataobject.TemplateDO;

import java.util.List;

/**
 * 情书模板 Service 接口
 *
 * @author vvnocode
 */
public interface TemplateService {

    /**
     * 创建模板
     *
     * @param templateDO 模板信息
     * @return 模板ID
     */
    Long createTemplate(TemplateDO templateDO);

    /**
     * 更新模板
     *
     * @param templateDO 模板信息
     */
    void updateTemplate(TemplateDO templateDO);

    /**
     * 删除模板
     *
     * @param id 模板ID
     */
    void deleteTemplate(Long id);

    /**
     * 获得模板
     *
     * @param id 模板ID
     * @return 模板信息
     */
    TemplateDO getTemplate(Long id);

    /**
     * 根据分类ID获得模板列表
     *
     * @param categoryId 分类ID
     * @return 模板列表
     */
    List<TemplateDO> getTemplatesByCategoryId(Long categoryId);

    /**
     * 根据风格获得模板列表
     *
     * @param style 风格
     * @return 模板列表
     */
    List<TemplateDO> getTemplatesByStyle(String style);

    /**
     * 获得热门模板列表
     *
     * @param limit 限制数量
     * @return 模板列表
     */
    List<TemplateDO> getHotTemplates(int limit);

    /**
     * 分页查询模板
     *
     * @param page       分页参数
     * @param categoryId 分类ID（可选）
     * @param style      风格（可选）
     * @param keyword    关键词（可选）
     * @return 分页结果
     */
    IPage<TemplateDO> getTemplatePage(Page<TemplateDO> page, Long categoryId, String style, String keyword);

    /**
     * 增加模板使用次数
     *
     * @param id 模板ID
     */
    void incrementUseCount(Long id);

    /**
     * 校验模板是否存在
     *
     * @param id 模板ID
     */
    void validateTemplateExists(Long id);

}