package org.qingshu.server.dal.dataobject;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 用户创作 DO
 *
 * @author vvnocode
 */
@TableName("qs_user_creation")
@Data
@EqualsAndHashCode(callSuper = true)
public class UserCreationDO extends BaseDO {

    /**
     * 创作ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 模板ID
     */
    private Long templateId;

    /**
     * 标题
     */
    private String title;

    /**
     * 内容
     */
    private String content;

    /**
     * 封面图片
     */
    private String coverImage;

    /**
     * 收件人姓名
     */
    private String recipientName;

    /**
     * 发送方式：1-在线查看，2-保存图片，3-邮件发送
     */
    private Integer sendMethod;

    /**
     * 是否公开到社区
     */
    private Boolean isPublic;

    /**
     * 点赞数
     */
    private Integer likeCount;

    /**
     * 评论数
     */
    private Integer commentCount;

    /**
     * 浏览数
     */
    private Integer viewCount;

    /**
     * 分享数
     */
    private Integer shareCount;

    /**
     * 状态：0-草稿，1-已发布
     */
    private Integer status;

}