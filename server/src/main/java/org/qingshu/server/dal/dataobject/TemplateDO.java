package org.qingshu.server.dal.dataobject;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 情书模板 DO
 *
 * @author vvnocode
 */
@TableName("qs_template")
@Data
@EqualsAndHashCode(callSuper = true)
public class TemplateDO extends BaseDO {

    /**
     * 模板ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 模板名称
     */
    private String name;

    /**
     * 模板描述
     */
    private String description;

    /**
     * 模板内容
     */
    private String content;

    /**
     * 封面图片
     */
    private String coverImage;

    /**
     * 分类ID
     */
    private Long categoryId;

    /**
     * 风格：romantic/birthday/anniversary/apology/gratitude
     */
    private String style;

    /**
     * 标签，逗号分隔
     */
    private String tags;

    /**
     * 使用次数
     */
    private Integer useCount;

    /**
     * 点赞数
     */
    private Integer likeCount;

    /**
     * 是否免费
     */
    private Boolean isFree;

    /**
     * 排序
     */
    private Integer sort;

    /**
     * 状态：0-禁用，1-启用
     */
    private Integer status;

}