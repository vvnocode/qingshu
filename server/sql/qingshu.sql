-- 青书平台数据库表结构
-- MariaDB 10.11

CREATE DATABASE IF NOT EXISTS `qingshu` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `qingshu`;

-- ----------------------------
-- 用户表
-- ----------------------------
CREATE TABLE `qs_user`
(
    `id`          bigint       NOT NULL AUTO_INCREMENT COMMENT '用户ID',
    `username`    varchar(50)  NOT NULL COMMENT '用户名',
    `password`    varchar(100) NOT NULL COMMENT '密码',
    `nickname`    varchar(50)  DEFAULT NULL COMMENT '昵称',
    `email`       varchar(100) DEFAULT NULL COMMENT '邮箱',
    `mobile`      varchar(20)  DEFAULT NULL COMMENT '手机号',
    `avatar`      varchar(255) DEFAULT NULL COMMENT '头像URL',
    `gender`      tinyint      DEFAULT 0 COMMENT '性别：0-未知，1-男，2-女',
    `birthday`    date         DEFAULT NULL COMMENT '生日',
    `status`      tinyint      DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
    `creator`     bigint       DEFAULT NULL COMMENT '创建者',
    `create_time` datetime     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater`     bigint       DEFAULT NULL COMMENT '更新者',
    `update_time` datetime     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`  bigint       DEFAULT 0 COMMENT '删除时间戳，0表示未删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`, `deleted_at`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='用户表';

-- ----------------------------
-- 情书模板表
-- ----------------------------
CREATE TABLE `qs_template`
(
    `id`          bigint       NOT NULL AUTO_INCREMENT COMMENT '模板ID',
    `name`        varchar(100) NOT NULL COMMENT '模板名称',
    `description` varchar(500) DEFAULT NULL COMMENT '模板描述',
    `content`     text         NOT NULL COMMENT '模板内容',
    `cover_image` varchar(255) DEFAULT NULL COMMENT '封面图片',
    `category_id` bigint       DEFAULT NULL COMMENT '分类ID',
    `style`       varchar(50)  DEFAULT NULL COMMENT '风格：romantic/birthday/anniversary/apology/gratitude',
    `tags`        varchar(255) DEFAULT NULL COMMENT '标签，逗号分隔',
    `use_count`   int          DEFAULT 0 COMMENT '使用次数',
    `like_count`  int          DEFAULT 0 COMMENT '点赞数',
    `is_free`     bit(1)       DEFAULT b'1' COMMENT '是否免费',
    `sort`        int          DEFAULT 0 COMMENT '排序',
    `status`      tinyint      DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
    `creator`     bigint       DEFAULT NULL COMMENT '创建者',
    `create_time` datetime     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater`     bigint       DEFAULT NULL COMMENT '更新者',
    `update_time` datetime     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`  bigint       DEFAULT 0 COMMENT '删除时间戳，0表示未删除',
    PRIMARY KEY (`id`),
    KEY `idx_category_id` (`category_id`),
    KEY `idx_style` (`style`),
    KEY `idx_sort` (`sort`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='情书模板表';

-- ----------------------------
-- 模板分类表
-- ----------------------------
CREATE TABLE `qs_template_category`
(
    `id`          bigint      NOT NULL AUTO_INCREMENT COMMENT '分类ID',
    `name`        varchar(50) NOT NULL COMMENT '分类名称',
    `description` varchar(255) DEFAULT NULL COMMENT '分类描述',
    `icon`        varchar(100) DEFAULT NULL COMMENT '图标',
    `sort`        int          DEFAULT 0 COMMENT '排序',
    `status`      tinyint      DEFAULT 1 COMMENT '状态：0-禁用，1-启用',
    `creator`     bigint       DEFAULT NULL COMMENT '创建者',
    `create_time` datetime     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater`     bigint       DEFAULT NULL COMMENT '更新者',
    `update_time` datetime     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`  bigint       DEFAULT 0 COMMENT '删除时间戳，0表示未删除',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='模板分类表';

-- ----------------------------
-- 用户创作表
-- ----------------------------
CREATE TABLE `qs_user_creation`
(
    `id`             bigint       NOT NULL AUTO_INCREMENT COMMENT '创作ID',
    `user_id`        bigint       NOT NULL COMMENT '用户ID',
    `template_id`    bigint       DEFAULT NULL COMMENT '模板ID',
    `title`          varchar(100) NOT NULL COMMENT '标题',
    `content`        text         NOT NULL COMMENT '内容',
    `cover_image`    varchar(255) DEFAULT NULL COMMENT '封面图片',
    `recipient_name` varchar(50)  DEFAULT NULL COMMENT '收件人姓名',
    `send_method`    tinyint      DEFAULT 1 COMMENT '发送方式：1-在线查看，2-保存图片，3-邮件发送',
    `is_public`      bit(1)       DEFAULT b'0' COMMENT '是否公开到社区',
    `like_count`     int          DEFAULT 0 COMMENT '点赞数',
    `comment_count`  int          DEFAULT 0 COMMENT '评论数',
    `view_count`     int          DEFAULT 0 COMMENT '浏览数',
    `share_count`    int          DEFAULT 0 COMMENT '分享数',
    `status`         tinyint      DEFAULT 1 COMMENT '状态：0-草稿，1-已发布',
    `creator`        bigint       DEFAULT NULL COMMENT '创建者',
    `create_time`    datetime     DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater`        bigint       DEFAULT NULL COMMENT '更新者',
    `update_time`    datetime     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`     bigint       DEFAULT 0 COMMENT '删除时间戳，0表示未删除',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_template_id` (`template_id`),
    KEY `idx_is_public` (`is_public`),
    KEY `idx_create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='用户创作表';

-- ----------------------------
-- 社区帖子表
-- ----------------------------
CREATE TABLE `qs_community_post`
(
    `id`            bigint       NOT NULL AUTO_INCREMENT COMMENT '帖子ID',
    `user_id`       bigint       NOT NULL COMMENT '用户ID',
    `creation_id`   bigint      DEFAULT NULL COMMENT '关联的创作ID',
    `title`         varchar(100) NOT NULL COMMENT '标题',
    `content`       text         NOT NULL COMMENT '内容',
    `images`        text        DEFAULT NULL COMMENT '图片URL，JSON数组格式',
    `topic`         varchar(50) DEFAULT NULL COMMENT '话题',
    `like_count`    int         DEFAULT 0 COMMENT '点赞数',
    `comment_count` int         DEFAULT 0 COMMENT '评论数',
    `share_count`   int         DEFAULT 0 COMMENT '分享数',
    `is_top`        bit(1)      DEFAULT b'0' COMMENT '是否置顶',
    `is_hot`        bit(1)      DEFAULT b'0' COMMENT '是否热门',
    `status`        tinyint     DEFAULT 1 COMMENT '状态：0-审核中，1-已发布，2-已下架',
    `creator`       bigint      DEFAULT NULL COMMENT '创建者',
    `create_time`   datetime    DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater`       bigint      DEFAULT NULL COMMENT '更新者',
    `update_time`   datetime    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`    bigint      DEFAULT 0 COMMENT '删除时间戳，0表示未删除',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_creation_id` (`creation_id`),
    KEY `idx_is_top` (`is_top`),
    KEY `idx_is_hot` (`is_hot`),
    KEY `idx_create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='社区帖子表';

-- ----------------------------
-- 评论表
-- ----------------------------
CREATE TABLE `qs_comment`
(
    `id`          bigint  NOT NULL AUTO_INCREMENT COMMENT '评论ID',
    `user_id`     bigint  NOT NULL COMMENT '用户ID',
    `target_type` tinyint NOT NULL COMMENT '目标类型：1-帖子，2-创作',
    `target_id`   bigint  NOT NULL COMMENT '目标ID',
    `parent_id`   bigint   DEFAULT NULL COMMENT '父评论ID',
    `content`     text    NOT NULL COMMENT '评论内容',
    `like_count`  int      DEFAULT 0 COMMENT '点赞数',
    `status`      tinyint  DEFAULT 1 COMMENT '状态：0-审核中，1-已发布，2-已下架',
    `creator`     bigint   DEFAULT NULL COMMENT '创建者',
    `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater`     bigint   DEFAULT NULL COMMENT '更新者',
    `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`  bigint   DEFAULT 0 COMMENT '删除时间戳，0表示未删除',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_target` (`target_type`, `target_id`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='评论表';

-- ----------------------------
-- 点赞表
-- ----------------------------
CREATE TABLE `qs_like`
(
    `id`          bigint  NOT NULL AUTO_INCREMENT COMMENT '点赞ID',
    `user_id`     bigint  NOT NULL COMMENT '用户ID',
    `target_type` tinyint NOT NULL COMMENT '目标类型：1-帖子，2-创作，3-评论',
    `target_id`   bigint  NOT NULL COMMENT '目标ID',
    `creator`     bigint   DEFAULT NULL COMMENT '创建者',
    `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater`     bigint   DEFAULT NULL COMMENT '更新者',
    `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`  bigint   DEFAULT 0 COMMENT '删除时间戳，0表示未删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_target` (`user_id`, `target_type`, `target_id`, `deleted_at`),
    KEY `idx_target` (`target_type`, `target_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='点赞表';

-- ----------------------------
-- 用户关注表
-- ----------------------------
CREATE TABLE `qs_user_follow`
(
    `id`           bigint NOT NULL AUTO_INCREMENT COMMENT '关注ID',
    `follower_id`  bigint NOT NULL COMMENT '关注者ID',
    `following_id` bigint NOT NULL COMMENT '被关注者ID',
    `creator`      bigint   DEFAULT NULL COMMENT '创建者',
    `create_time`  datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updater`      bigint   DEFAULT NULL COMMENT '更新者',
    `update_time`  datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at`   bigint   DEFAULT 0 COMMENT '删除时间戳，0表示未删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_follower_following` (`follower_id`, `following_id`, `deleted_at`),
    KEY `idx_following_id` (`following_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci COMMENT ='用户关注表';

-- ----------------------------
-- 初始化数据
-- ----------------------------

-- 插入模板分类
INSERT INTO `qs_template_category` (`name`, `description`, `icon`, `sort`, `creator`)
VALUES ('浪漫告白', '表达爱意的浪漫情书', 'fa-heart', 1, 1),
       ('生日祝福', '生日时的温馨祝福', 'fa-birthday-cake', 2, 1),
       ('纪念日', '纪念特殊日子的情书', 'fa-calendar-heart', 3, 1),
       ('道歉和好', '表达歉意的真诚情书', 'fa-handshake', 4, 1),
       ('感恩表达', '表达感激之情', 'fa-praying-hands', 5, 1),
       ('节日祝福', '各种节日的温馨祝福', 'fa-gift', 6, 1),
       ('励志鼓励', '给予对方力量和支持', 'fa-star', 7, 1),
       ('思念想念', '表达思念之情', 'fa-heart-broken', 8, 1);

-- 插入情书模板
INSERT INTO `qs_template` (`name`, `description`, `content`, `category_id`, `style`, `tags`, `use_count`, `creator`)
VALUES ('心动时刻', '表达初次心动的感觉，温柔而浪漫',
        '亲爱的{收件人}：\n\n从遇见你的那一刻起，我的世界就变得不一样了。你的笑容像春天的阳光，温暖了我的心房。每一次与你的相遇，都让我感受到前所未有的心动。\n\n愿意与你分享我生命中的每一个美好瞬间。\n\n永远爱你的{发件人}',
        1, 'romantic', '心动,初恋,温柔', 3200, 1),
       ('星空约定', '适合纪念日，表达长久的承诺与爱意',
        '我的挚爱{收件人}：\n\n还记得我们一起看星空的那个夜晚吗？满天繁星见证了我们的约定。无论时光如何流转，我对你的爱永不改变。\n\n愿我们的爱情如星空般永恒闪耀。\n\n此生挚爱{发件人}',
        3, 'anniversary', '星空,约定,纪念日', 2700, 1),
       ('生日甜蜜', '为爱人送上最甜蜜的生日祝福',
        '生日快乐，我的宝贝{收件人}：\n\n今天是属于你的特殊日子，愿所有的美好都围绕在你身边。你的每一岁生日，都是我们爱情故事中最珍贵的篇章。\n\n愿你的笑容永远如今天般灿烂。\n\n爱你的{发件人}',
        2, 'birthday', '生日,甜蜜,祝福', 1800, 1);

-- 插入测试用户
INSERT INTO `qs_user` (`username`, `password`, `nickname`, `email`, `mobile`, `gender`, `birthday`, `creator`)
VALUES ('admin', '$2a$10$N.ZOn9G6/YLFixAOPMg/h.z7pClinQZn4KPNI8j7GvjCTRGqRpG', '管理员', 'admin@qingshu.com',
        '13800138888', 0, '1990-01-01', 1),
       ('xiaoshi', '$2a$10$N.ZOn9G6/YLFixAOPMg/h.z7pClinQZn4KPNI8j7GvjCTRGqRpG', '小诗', 'xiaoshi@qingshu.com',
        '13800138000', 2, '1995-05-20', 1),
       ('xiaohang', '$2a$10$N.ZOn9G6/YLFixAOPMg/h.z7pClinQZn4KPNI8j7GvjCTRGqRpG', '小航', 'xiaohang@qingshu.com',
        '13800138001', 1, '1992-08-15', 1),
       ('mengmeng', '$2a$10$N.ZOn9G6/YLFixAOPMg/h.z7pClinQZn4KPNI8j7GvjCTRGqRpG', '萌萌', 'mengmeng@qingshu.com',
        '13800138002', 2, '1996-12-10', 1),
       ('xiaoyu', '$2a$10$N.ZOn9G6/YLFixAOPMg/h.z7pClinQZn4KPNI8j7GvjCTRGqRpG', '小宇', 'xiaoyu@qingshu.com',
        '13800138003', 1, '1993-03-25', 1),
       ('linlin', '$2a$10$N.ZOn9G6/YLFixAOPMg/h.z7pClinQZn4KPNI8j7GvjCTRGqRpG', '琳琳', 'linlin@qingshu.com',
        '13800138004', 2, '1997-07-08', 1),
       ('demo', '$2a$10$N.ZOn9G6/YLFixAOPMg/h.z7pClinQZn4KPNI8j7GvjCTRGqRpG', '演示用户', 'demo@qingshu.com',
        '13800138888', 1, '1991-11-11', 1);

-- 插入用户创作示例
INSERT INTO `qs_user_creation` (`user_id`, `template_id`, `title`, `content`, `recipient_name`, `is_public`,
                                `like_count`, `view_count`, `creator`)
VALUES (2, 1, '给小航的心动告白',
        '亲爱的小航：\n\n从遇见你的那一刻起，我的世界就变得不一样了。你的笑容像春天的阳光，温暖了我的心房。每一次与你的相遇，都让我感受到前所未有的心动。\n\n愿意与你分享我生命中的每一个美好瞬间。\n\n永远爱你的小诗',
        '小航', 1, 25, 156, 2),
       (3, 4, '我们的星空约定',
        '我的挚爱小诗：\n\n还记得我们一起看星空的那个夜晚吗？满天繁星见证了我们的约定。无论时光如何流转，我对你的爱永不改变。\n\n愿我们的爱情如星空般永恒闪耀。\n\n此生挚爱小航',
        '小诗', 1, 32, 198, 3),
       (4, 5, '生日快乐，我的宝贝',
        '生日快乐，我的宝贝小宇：\n\n今天是属于你的特殊日子，愿所有的美好都围绕在你身边。你的每一岁生日，都是我们爱情故事中最珍贵的篇章。\n\n愿你的笑容永远如今天般灿烂。\n\n爱你的萌萌',
        '小宇', 1, 18, 89, 4);

-- 插入社区帖子
INSERT INTO `qs_community_post` (`user_id`, `creation_id`, `title`, `content`, `topic`, `like_count`, `comment_count`,
                                 `is_hot`, `creator`)
VALUES (2, 1, '分享我的第一封情书', '刚刚完成了我人生中的第一封情书，内心既紧张又兴奋。希望他能喜欢💕', '情书分享', 45, 12,
        1, 2),
       (3, 2, '星空下的约定成真了', '还记得那个夜晚我们许下的约定，现在终于实现了。爱情真的很美好❤️', '甜蜜日常', 38, 8,
        0, 3),
       (4, NULL, '如何写出打动人心的情书？', '想给男朋友写情书，但是不知道怎么开始。大家有什么好的建议吗？', '求助交流', 23,
        15, 0, 4),
       (5, NULL, '情书模板使用心得', '用了几个模板，感觉效果都不错，关键是要真情实感。分享一些使用技巧给大家。', '经验分享',
        56, 20, 1, 5),
       (6, NULL, '纪念日快乐！', '今天是我们在一起一周年纪念日，想和大家分享这份快乐😊', '纪念日', 67, 25, 1, 6);

-- 插入评论
INSERT INTO `qs_comment` (`user_id`, `target_type`, `target_id`, `content`, `like_count`, `creator`)
VALUES (3, 1, 1, '写得真好，很感动！', 5, 3),
       (4, 1, 1, '满满的爱意，好甜蜜', 3, 4),
       (5, 1, 1, '我也想写一封这样的情书', 2, 5),
       (2, 1, 2, '你们真的好幸福啊！', 4, 2),
       (6, 1, 2, '羡慕你们的爱情', 6, 6),
       (2, 1, 4, '可以先从模板开始，然后加入自己的情感', 8, 2),
       (3, 1, 4, '真情实感最重要，不用太华丽的辞藻', 7, 3),
       (5, 1, 4, '我觉得可以写一些你们共同的回忆', 5, 5),
       (6, 1, 4, '推荐先看看别人的作品找找灵感', 4, 6),
       (2, 1, 5, '谢谢分享，很实用的建议', 6, 2),
       (3, 1, 5, '确实，模板只是工具，情感才是核心', 5, 3),
       (4, 1, 5, '我按照你的建议试了试，效果很好', 3, 4);

-- 插入点赞记录
INSERT INTO `qs_like` (`user_id`, `target_type`, `target_id`, `creator`)
VALUES
-- 帖子点赞
(3, 1, 1, 3),
(4, 1, 1, 4),
(5, 1, 1, 5),
(6, 1, 1, 6),
(2, 1, 2, 2),
(4, 1, 2, 4),
(5, 1, 2, 5),
(6, 1, 2, 6),
(2, 1, 4, 2),
(3, 1, 4, 3),
(5, 1, 4, 5),
-- 评论点赞
(2, 3, 1, 2),
(4, 3, 1, 4),
(5, 3, 1, 5),
(3, 3, 2, 3),
(4, 3, 2, 4),
(5, 3, 2, 5),
(4, 3, 6, 4),
(5, 3, 6, 5),
(6, 3, 6, 6),
-- 创作点赞
(3, 2, 1, 3),
(4, 2, 1, 4),
(5, 2, 1, 5),
(6, 2, 1, 6),
(2, 2, 2, 2),
(4, 2, 2, 4),
(5, 2, 2, 5),
(6, 2, 2, 6),
(2, 2, 3, 2),
(3, 2, 3, 3),
(5, 2, 3, 5);