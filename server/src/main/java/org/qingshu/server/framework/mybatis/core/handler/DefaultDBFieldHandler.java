package org.qingshu.server.framework.mybatis.core.handler;

import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 通用字段填充器
 * 自动填充创建时间、更新时间、创建者、更新者等字段
 *
 * @author vvnocode
 */
@Component
public class DefaultDBFieldHandler implements MetaObjectHandler {

    @Override
    public void insertFill(MetaObject metaObject) {
        LocalDateTime now = LocalDateTime.now();

        // 填充创建时间
        if (metaObject.hasGetter("createTime")) {
            setFieldValByName("createTime", now, metaObject);
        }

        // 填充更新时间
        if (metaObject.hasGetter("updateTime")) {
            setFieldValByName("updateTime", now, metaObject);
        }

        // 填充创建者（暂时使用固定值1，实际项目中应该从当前登录用户获取）
        if (metaObject.hasGetter("creator")) {
            setFieldValByName("creator", 1L, metaObject);
        }

        // 填充更新者
        if (metaObject.hasGetter("updater")) {
            setFieldValByName("updater", 1L, metaObject);
        }

        // 确保新记录的删除标记为0（未删除）
        if (metaObject.hasGetter("deletedAt")) {
            Object deletedAt = getFieldValByName("deletedAt", metaObject);
            if (deletedAt == null) {
                setFieldValByName("deletedAt", 0L, metaObject);
            }
        }
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        // 填充更新时间
        if (metaObject.hasGetter("updateTime")) {
            setFieldValByName("updateTime", LocalDateTime.now(), metaObject);
        }

        // 填充更新者（暂时使用固定值1，实际项目中应该从当前登录用户获取）
        if (metaObject.hasGetter("updater")) {
            setFieldValByName("updater", 1L, metaObject);
        }
    }

}