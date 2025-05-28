package org.qingshu.server.dal.dataobject;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 社区帖子 DO
 *
 * @author vvnocode
 */
@TableName("qs_community_post")
@Data
@EqualsAndHashCode(callSuper = true)
public class CommunityPostDO extends BaseDO {

    /**
     * 帖子ID
     */
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 用户ID
     */
    private Long userId;

    /**
     * 关联的创作ID
     */
    private Long creationId;

    /**
     * 标题
     */
    private String title;

    /**
     * 内容
     */
    private String content;

    /**
     * 图片URL，JSON数组格式
     */
    private String images;

    /**
     * 话题
     */
    private String topic;

    /**
     * 点赞数
     */
    private Integer likeCount;

    /**
     * 评论数
     */
    private Integer commentCount;

    /**
     * 分享数
     */
    private Integer shareCount;

    /**
     * 是否置顶
     */
    private Boolean isTop;

    /**
     * 是否热门
     */
    private Boolean isHot;

    /**
     * 状态：0-审核中，1-已发布，2-已下架
     */
    private Integer status;

} 