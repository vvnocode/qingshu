package org.qingshu.server.dal.mysql;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.apache.ibatis.annotations.Mapper;
import org.qingshu.server.dal.dataobject.TemplateDO;

import java.util.List;

/**
 * 情书模板 Mapper
 *
 * @author vvnocode
 */
@Mapper
public interface TemplateMapper extends BaseMapper<TemplateDO> {

    /**
     * 根据分类ID查询模板列表
     *
     * @param categoryId 分类ID
     * @return 模板列表
     */
    default List<TemplateDO> selectByCategoryId(Long categoryId) {
        return selectList(new LambdaQueryWrapper<TemplateDO>()
                .eq(TemplateDO::getCategoryId, categoryId)
                .eq(TemplateDO::getStatus, 1)
                .orderByDesc(TemplateDO::getSort)
                .orderByDesc(TemplateDO::getCreateTime));
    }

    /**
     * 根据风格查询模板列表
     *
     * @param style 风格
     * @return 模板列表
     */
    default List<TemplateDO> selectByStyle(String style) {
        return selectList(new LambdaQueryWrapper<TemplateDO>()
                .eq(TemplateDO::getStyle, style)
                .eq(TemplateDO::getStatus, 1)
                .orderByDesc(TemplateDO::getSort)
                .orderByDesc(TemplateDO::getCreateTime));
    }

    /**
     * 查询热门模板（按使用次数排序）
     *
     * @param limit 限制数量
     * @return 模板列表
     */
    default List<TemplateDO> selectHotTemplates(int limit) {
        return selectList(new LambdaQueryWrapper<TemplateDO>()
                .eq(TemplateDO::getStatus, 1)
                .orderByDesc(TemplateDO::getUseCount)
                .orderByDesc(TemplateDO::getLikeCount)
                .last("LIMIT " + limit));
    }

    /**
     * 分页查询模板
     *
     * @param page       分页参数
     * @param categoryId 分类ID（可选）
     * @param style      风格（可选）
     * @param keyword    关键词（可选）
     * @return 分页结果
     */
    default IPage<TemplateDO> selectPage(Page<TemplateDO> page, Long categoryId, String style, String keyword) {
        LambdaQueryWrapper<TemplateDO> wrapper = new LambdaQueryWrapper<TemplateDO>()
                .eq(TemplateDO::getStatus, 1);
        
        if (categoryId != null) {
            wrapper.eq(TemplateDO::getCategoryId, categoryId);
        }
        
        if (style != null && !style.isEmpty()) {
            wrapper.eq(TemplateDO::getStyle, style);
        }
        
        if (keyword != null && !keyword.isEmpty()) {
            wrapper.and(w -> w.like(TemplateDO::getName, keyword)
                    .or().like(TemplateDO::getDescription, keyword)
                    .or().like(TemplateDO::getTags, keyword));
        }
        
        wrapper.orderByDesc(TemplateDO::getSort)
                .orderByDesc(TemplateDO::getCreateTime);
        
        return selectPage(page, wrapper);
    }

} 